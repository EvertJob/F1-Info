#!/usr/bin/env python3
"""
Scrape the latest FIA "PU elements used per driver up to now" PDF for the configured
season page, parse tables with pdfplumber, and upsert rows into Supabase PostgreSQL.

Environment:
    DATABASE_URL  — PostgreSQL connection URI (e.g. Supabase pooler or direct).

Usage:
    python scripts/sync_fia_data.py

GitHub Actions: set DATABASE_URL secret; optional FIA_SEASON_URL override.
"""
from __future__ import annotations

import io
import logging
import os
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Iterable
from urllib.parse import urljoin, urlparse

import pdfplumber
import psycopg2
import requests
from bs4 import BeautifulSoup
from psycopg2.extras import execute_values

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%SZ",
)
log = logging.getLogger("sync_fia_data")

DEFAULT_FIA_SEASON_URL = (
    "https://www.fia.com/documents/championships/"
    "fia-formula-one-world-championship-14/season/season-2026-2072"
)

PU_LINK_SUBSTRING = "pu elements used per driver up to now"

REQUEST_TIMEOUT = 60
USER_AGENT = (
    "Mozilla/5.0 (compatible; F1HubPU-Sync/1.0; +https://github.com/EvertJob/F1-Info)"
)

# Listing line: "Doc 9 - PU elements used per driver up to nowPublished on 13.03.26 00:00 CET"
DOC_AND_TITLE_RE = re.compile(
    r"Doc\s+(\d+)\s*[-–—]\s*([^<\n]+?)(?:Published\s+on\s+(\d{2}\.\d{2}\.\d{2})\s+(\d{2}:\d{2})\s*CET)?",
    re.IGNORECASE | re.DOTALL,
)

# PDF body (first page): "Doc 9" or "Document 9" / revised wording
PDF_DOC_NUM_RE = re.compile(
    r"(?:Doc(?:ument)?|DOC)\s*[.:]?\s*(\d+)",
    re.IGNORECASE,
)
PDF_REVISED_RE = re.compile(r"\brevised\b", re.IGNORECASE)

HEADER_ALIASES = {
    "ice": "ice",
    "tc": "tc",
    "t/c": "tc",
    "mguk": "mguk",
    "mgu-k": "mguk",
    "mgu_k": "mguk",
    "mgu k": "mguk",
    "es": "es",
    "ce": "ce",
    "ex": "ex",
    "driver": "driver",
    "driver name": "driver",
    "car": "car",
    "no": "car",
    "no.": "car",
    "#": "car",
}


@dataclass(frozen=True)
class ListingMatch:
    doc_number: int
    url: str
    anchor_text: str
    published_at: datetime | None


@dataclass(frozen=True)
class DriverPURow:
    driver_name: str
    ice_count: int | None
    tc_count: int | None
    mguk_count: int | None
    es_count: int | None
    ce_count: int | None
    ex_count: int | None


def _session() -> requests.Session:
    s = requests.Session()
    s.headers.update({"User-Agent": USER_AGENT, "Accept-Language": "en-GB,en;q=0.9"})
    return s


def fetch_season_html(url: str) -> str:
    with _session() as sess:
        r = sess.get(url, timeout=REQUEST_TIMEOUT)
        r.raise_for_status()
    return r.text


def _parse_published_cet(day: str, hm: str) -> datetime | None:
    try:
        dt = datetime.strptime(f"{day} {hm}", "%d.%m.%y %H:%M")
        return dt.replace(tzinfo=timezone.utc)
    except ValueError:
        return None


def find_pu_document_links(html: str, base_url: str) -> list[ListingMatch]:
    soup = BeautifulSoup(html, "html.parser")
    out: list[ListingMatch] = []
    for a in soup.find_all("a", href=True):
        href = a["href"].strip()
        if not href.lower().endswith(".pdf"):
            continue
        if "decision-document" not in href.lower():
            continue
        text = " ".join(a.get_text(separator=" ", strip=True).split())
        title = (a.get("title") or "").strip()
        blob = f"{text} {title}".lower()
        if PU_LINK_SUBSTRING not in blob:
            continue
        full_url = urljoin(base_url, href)
        combined = f"{text} {title}".strip()
        m = DOC_AND_TITLE_RE.search(combined)
        doc_number = int(m.group(1)) if m else 0
        pub = None
        if m and m.group(3) and m.group(4):
            pub = _parse_published_cet(m.group(3), m.group(4))
        out.append(
            ListingMatch(
                doc_number=doc_number,
                url=full_url,
                anchor_text=combined,
                published_at=pub,
            )
        )
    # De-dupe by URL
    by_url: dict[str, ListingMatch] = {}
    for m in out:
        prev = by_url.get(m.url)
        if prev is None or (m.published_at or datetime.min.replace(tzinfo=timezone.utc)) >= (
            prev.published_at or datetime.min.replace(tzinfo=timezone.utc)
        ):
            by_url[m.url] = m
    return list(by_url.values())


def pick_latest_listing(matches: Iterable[ListingMatch]) -> ListingMatch | None:
    matches = list(matches)
    if not matches:
        return None

    def sort_key(m: ListingMatch) -> tuple:
        ts = m.published_at or datetime.min.replace(tzinfo=timezone.utc)
        return (ts, m.doc_number)

    return max(matches, key=sort_key)


def download_pdf(url: str) -> bytes:
    with _session() as sess:
        r = sess.get(url, timeout=REQUEST_TIMEOUT)
        r.raise_for_status()
        if not r.content.startswith(b"%PDF"):
            raise ValueError(f"Expected PDF bytes from {url!r}")
    return r.content


def extract_pdf_doc_metadata(first_page_text: str) -> tuple[int | None, bool]:
    if not first_page_text:
        return None, False
    revised = bool(PDF_REVISED_RE.search(first_page_text))
    doc_num: int | None = None
    for m in PDF_DOC_NUM_RE.finditer(first_page_text):
        try:
            n = int(m.group(1))
        except ValueError:
            continue
        doc_num = max(doc_num or 0, n)
    return doc_num, revised


def _norm_header(cell: str | None) -> str:
    if cell is None:
        return ""
    s = cell.strip().lower()
    s = re.sub(r"\s+", " ", s)
    s = s.replace("\n", " ")
    return s


def _map_header_to_field(h: str) -> str | None:
    h = _norm_header(h)
    h = h.strip(".")
    return HEADER_ALIASES.get(h)


def _parse_int_cell(v: str | None) -> int | None:
    if v is None:
        return None
    t = re.sub(r"[^\d]", "", str(v).strip())
    if t == "":
        return None
    return int(t)


def _is_probable_driver_name(s: str) -> bool:
    s = s.strip()
    if len(s) < 3:
        return False
    if re.fullmatch(r"\d+", s):
        return False
    return bool(re.search(r"[a-zA-ZÀ-ÿ]", s))


def parse_pu_tables_from_pdf(pdf_bytes: bytes) -> tuple[list[DriverPURow], int | None, bool]:
    rows_out: list[DriverPURow] = []
    pdf_doc_num: int | None = None
    pdf_revised = False

    with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
        if not pdf.pages:
            return [], None, False
        first_text = pdf.pages[0].extract_text() or ""
        pdf_doc_num, pdf_revised = extract_pdf_doc_metadata(first_text)

        for page in pdf.pages:
            tables = page.extract_tables() or []
            for table in tables:
                if not table or len(table) < 2:
                    continue
                header_idx = None
                colmap: dict[str, int] = {}
                for i, row in enumerate(table[:8]):
                    if not row:
                        continue
                    tentative: dict[str, int] = {}
                    for j, cell in enumerate(row):
                        field = _map_header_to_field(cell)
                        if field and field not in tentative:
                            tentative[field] = j
                    need = {"ice", "tc", "mguk", "es", "ce", "ex"}
                    if need.issubset(tentative.keys()):
                        header_idx = i
                        colmap = tentative
                        break
                if header_idx is None:
                    continue

                driver_col = colmap.get("driver")
                if driver_col is None:
                    # Use first text column that is not mapped as PU column
                    used = set(colmap.values())
                    for j, _ in enumerate(table[header_idx]):
                        if j in used:
                            continue
                        driver_col = j
                        break

                for row in table[header_idx + 1 :]:
                    if not row or len(row) <= max(colmap.values(), default=0):
                        continue
                    driver_cell = (
                        row[driver_col].strip() if driver_col is not None and driver_col < len(row) else ""
                    )
                    if not _is_probable_driver_name(driver_cell):
                        continue
                    # Skip repeated header lines
                    if _norm_header(driver_cell) in ("driver", "driver name"):
                        continue

                    def col(name: str) -> int | None:
                        idx = colmap.get(name)
                        if idx is None or idx >= len(row):
                            return None
                        return _parse_int_cell(row[idx])

                    rows_out.append(
                        DriverPURow(
                            driver_name=re.sub(r"\s+", " ", driver_cell).strip(),
                            ice_count=col("ice"),
                            tc_count=col("tc"),
                            mguk_count=col("mguk"),
                            es_count=col("es"),
                            ce_count=col("ce"),
                            ex_count=col("ex"),
                        )
                    )

    # De-dupe drivers (keep last occurrence in PDF — usually the final table wins)
    by_name: dict[str, DriverPURow] = {}
    for r in rows_out:
        by_name[r.driver_name.casefold()] = r
    return list(by_name.values()), pdf_doc_num, pdf_revised


def resolve_doc_number(
    listing: ListingMatch, pdf_doc_num: int | None, pdf_revised: bool
) -> tuple[int, bool]:
    """
    Prefer the document number found inside the PDF (authoritative for Revised issuances).
    If the PDF mentions a higher doc number than the listing anchor, trust the PDF.
    """
    listed = listing.doc_number
    if pdf_doc_num is None:
        return listed, pdf_revised
    # Revised bulletins sometimes keep the same listing slug; PDF body is source of truth.
    return max(listed, pdf_doc_num), pdf_revised


def upsert_rows(
    conn: Any,
    fia_pdf_url: str,
    fia_doc_number: int,
    is_revised: bool,
    rows: list[DriverPURow],
) -> None:
    """
    Default: INSERT ... ON CONFLICT (fia_pdf_url, driver_name) DO UPDATE (see
    supabase/sql/fia_pu_elements.sql).

    Set FIA_PU_DELETE_BEFORE_INSERT=1 to DELETE all rows for this URL then INSERT — useful
    when you cannot add a composite unique key (still stores multiple driver rows per URL).
    """
    if not rows:
        log.warning("No driver rows parsed; skipping database write")
        return

    now = datetime.now(timezone.utc)
    values = [
        (
            fia_pdf_url,
            fia_doc_number,
            is_revised,
            r.driver_name,
            r.ice_count,
            r.tc_count,
            r.mguk_count,
            r.es_count,
            r.ce_count,
            r.ex_count,
            now,
        )
        for r in rows
    ]

    use_delete = os.environ.get("FIA_PU_DELETE_BEFORE_INSERT", "").lower() in (
        "1",
        "true",
        "yes",
    )

    insert_cols = """
        INSERT INTO public.fia_pu_elements (
            fia_pdf_url, fia_doc_number, is_revised, driver_name,
            ice_count, tc_count, mguk_count, es_count, ce_count, ex_count, updated_at
        ) VALUES %s
    """

    with conn.cursor() as cur:
        if use_delete:
            cur.execute(
                "DELETE FROM public.fia_pu_elements WHERE fia_pdf_url = %s",
                (fia_pdf_url,),
            )
            execute_values(cur, insert_cols.strip(), values, page_size=100)
        else:
            upsert_sql = (
                insert_cols
                + """
        ON CONFLICT (fia_pdf_url, driver_name)
        DO UPDATE SET
            fia_doc_number = EXCLUDED.fia_doc_number,
            is_revised = EXCLUDED.is_revised,
            ice_count = EXCLUDED.ice_count,
            tc_count = EXCLUDED.tc_count,
            mguk_count = EXCLUDED.mguk_count,
            es_count = EXCLUDED.es_count,
            ce_count = EXCLUDED.ce_count,
            ex_count = EXCLUDED.ex_count,
            updated_at = EXCLUDED.updated_at
    """
            )
            execute_values(cur, upsert_sql.strip(), values, page_size=100)
    conn.commit()
    log.info(
        "Wrote %d driver row(s) for %s (delete_before_insert=%s)",
        len(values),
        fia_pdf_url,
        use_delete,
    )


def connect_db(dsn: str) -> Any:
    # Supabase typically requires TLS (pooler URLs may omit sslmode).
    lower = dsn.lower()
    if "sslmode=" not in lower:
        sep = "&" if "?" in dsn else "?"
        dsn = f"{dsn}{sep}sslmode=require"
    return psycopg2.connect(dsn)


def main() -> int:
    dsn = os.environ.get("DATABASE_URL")
    if not dsn:
        log.error("DATABASE_URL is not set")
        return 1

    season_url = os.environ.get("FIA_SEASON_URL", DEFAULT_FIA_SEASON_URL)
    log.info("Fetching season page %s", season_url)

    try:
        html = fetch_season_html(season_url)
    except requests.RequestException as e:
        log.error("Failed to fetch season page: %s", e)
        return 1

    base = f"{urlparse(season_url).scheme}://{urlparse(season_url).netloc}"
    matches = find_pu_document_links(html, base)
    if not matches:
        log.error("No PDF link containing %r found on the season page", PU_LINK_SUBSTRING)
        return 1

    chosen = pick_latest_listing(matches)
    assert chosen is not None
    log.info(
        "Selected listing Doc %s published=%s url=%s",
        chosen.doc_number,
        chosen.published_at,
        chosen.url,
    )

    try:
        pdf_bytes = download_pdf(chosen.url)
    except (requests.RequestException, ValueError) as e:
        log.error("Failed to download PDF: %s", e)
        return 1

    rows, pdf_doc_num, pdf_revised = parse_pu_tables_from_pdf(pdf_bytes)
    doc_number, is_revised = resolve_doc_number(chosen, pdf_doc_num, pdf_revised)

    log.info(
        "Parsed %d driver row(s); doc_number=%s (listing=%s pdf=%s) revised=%s",
        len(rows),
        doc_number,
        chosen.doc_number,
        pdf_doc_num,
        is_revised,
    )
    if rows[:3]:
        for preview in rows[:3]:
            log.debug("Row preview: %s", preview)

    try:
        conn = connect_db(dsn)
    except psycopg2.Error as e:
        log.error("Database connection failed: %s", e)
        return 1

    try:
        upsert_rows(conn, chosen.url, doc_number, is_revised, rows)
    except psycopg2.Error as e:
        log.error("Database upsert failed: %s", e)
        conn.rollback()
        return 1
    finally:
        conn.close()

    return 0


if __name__ == "__main__":
    sys.exit(main())
