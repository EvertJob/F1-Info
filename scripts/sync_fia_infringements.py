#!/usr/bin/env python3
"""
Scrape FIA Formula 1 season decision pages for links whose text contains
"Infringement" (PDF), parse each document with pdfplumber, and upsert one row
per PDF into Supabase PostgreSQL (unique on fia_pdf_url).

Extracted fields include event_name (Grand Prix), incident_time (ISO UTC when
parsable, else raw text), driver/team, session, fact, infringement, decision,
reason.

Environment:
    DATABASE_URL       — PostgreSQL URI (Supabase). Never log this value.

Optional:
    FIA_SEASON_URL     — Override season listing URL (default: 2026 F1 page).
    FIA_INFRINGEMENT_MAX_PDFS — Max PDFs to process per run (integer, for testing).

GitHub Actions: pass DATABASE_URL via encrypted secret; use workflow_dispatch or schedule.
"""
from __future__ import annotations

import io
import logging
import os
import random
import re
import sys
import time
import traceback
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import unquote, urljoin, urlparse

try:
    from zoneinfo import ZoneInfo
except ImportError:  # Python < 3.9 (unlikely in CI)
    ZoneInfo = None  # type: ignore[misc, assignment]

import pdfplumber
import psycopg2
import requests
from bs4 import BeautifulSoup

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%SZ",
)
log = logging.getLogger("sync_fia_infringements")

DEFAULT_FIA_SEASON_URL = (
    "https://www.fia.com/documents/championships/"
    "fia-formula-one-world-championship-14/season/season-2026-2072"
)

REQUEST_TIMEOUT = 60

# Realistic desktop Chrome on Windows (reduces 403s vs bot-style / custom UA strings).
BROWSER_USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/131.0.0.0 Safari/537.36"
)

# Jitter (seconds): after listing page, between PDF downloads (anti rate-limit).
DELAY_AFTER_LISTING_MIN = 1.2
DELAY_AFTER_LISTING_MAX = 3.8
DELAY_BETWEEN_PDFS_MIN = 0.7
DELAY_BETWEEN_PDFS_MAX = 2.4

# Listing: "Doc 58 - Infringement - ...Published on 14.03.26 09:30 CET"
DOC_LISTING_RE = re.compile(
    r"Doc\s+(\d+)\s*[-–—]\s*([^<\n]+?)(?:Published\s+on\s+(\d{2}\.\d{2}\.\d{2})\s+(\d{2}:\d{2})\s*CET)?",
    re.IGNORECASE | re.DOTALL,
)

PDF_DOC_NUM_RE = re.compile(
    r"(?:Doc(?:ument)?|DOC)\s*[.:]?\s*(\d+)",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class InfringementLink:
    url: str
    doc_number: int
    listing_title: str
    published_at: datetime | None


@dataclass
class InfringementRecord:
    fia_pdf_url: str
    fia_doc_number: int | None
    listing_title: str | None
    list_published_at: datetime | None
    event_name: str | None
    incident_time: str | None
    driver_and_team: str | None
    session_name: str | None
    fact: str | None
    infringement_rule: str | None
    decision: str | None
    reason: str | None


def _configure_browser_session(sess: requests.Session) -> None:
    """Browser-like defaults; Session keeps cookies across listing + PDF GETs."""
    sess.headers.update(
        {
            "User-Agent": BROWSER_USER_AGENT,
            "Accept": (
                "text/html,application/xhtml+xml,application/xml;q=0.9,"
                "image/avif,image/webp,image/apng,*/*;q=0.8"
            ),
            "Accept-Language": "en-GB,en-US;q=0.9,en;q=0.8",
            "Accept-Encoding": "gzip, deflate",
            "DNT": "1",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
            "Cache-Control": "max-age=0",
        }
    )


def create_fia_session() -> requests.Session:
    sess = requests.Session()
    _configure_browser_session(sess)
    return sess


def warm_up_fia_session(sess: requests.Session) -> None:
    """Optional first hit to fia.com to obtain cookies before the documents page."""
    try:
        r = sess.get("https://www.fia.com/", timeout=REQUEST_TIMEOUT, allow_redirects=True)
        r.raise_for_status()
        time.sleep(random.uniform(0.4, 1.2))
    except requests.RequestException as e:
        log.warning("Session warm-up (homepage) failed: %s — continuing", e)


def fetch_season_html(url: str, sess: requests.Session) -> str:
    # After homepage warm-up, following fia.com URLs are same-site navigations.
    sess.headers["Sec-Fetch-Site"] = "same-origin"
    r = sess.get(url, timeout=REQUEST_TIMEOUT, allow_redirects=True)
    r.raise_for_status()
    return r.text


def download_pdf(url: str, sess: requests.Session) -> bytes:
    r = sess.get(
        url,
        timeout=REQUEST_TIMEOUT,
        allow_redirects=True,
        headers={
            "Accept": "application/pdf,application/octet-stream,*/*;q=0.8",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
        },
    )
    r.raise_for_status()
    if not r.content.startswith(b"%PDF"):
        raise ValueError(f"Not a PDF: {url!r}")
    return r.content


def _parse_published_cet(day: str, hm: str) -> datetime | None:
    try:
        dt = datetime.strptime(f"{day} {hm}", "%d.%m.%y %H:%M")
        return dt.replace(tzinfo=timezone.utc)
    except ValueError:
        return None


def find_infringement_pdf_links(html: str, base_url: str) -> list[InfringementLink]:
    soup = BeautifulSoup(html, "html.parser")
    by_url: dict[str, InfringementLink] = {}

    for a in soup.find_all("a", href=True):
        href = a["href"].strip()
        if not href.lower().endswith(".pdf"):
            continue
        if "decision-document" not in href.lower():
            continue
        text = " ".join(a.get_text(separator=" ", strip=True).split())
        title = (a.get("title") or "").strip()
        blob = f"{text} {title}"
        if not any(word in blob.lower() for word in ["infringement", "decision", "summons"]):
            continue

        full_url = urljoin(base_url, href)
        combined = f"{text} {title}".strip()
        m = DOC_LISTING_RE.search(combined)
        doc_number = int(m.group(1)) if m else 0
        pub: datetime | None = None
        if m and m.group(3) and m.group(4):
            pub = _parse_published_cet(m.group(3), m.group(4))

        entry = InfringementLink(
            url=full_url,
            doc_number=doc_number,
            listing_title=combined[:2000],
            published_at=pub,
        )
        prev = by_url.get(full_url)
        if prev is None or (pub or datetime.min.replace(tzinfo=timezone.utc)) >= (
            prev.published_at or datetime.min.replace(tzinfo=timezone.utc)
        ):
            by_url[full_url] = entry

    return sorted(by_url.values(), key=lambda x: (x.published_at or datetime.min, x.url))


def _collapse_ws(s: str) -> str:
    return re.sub(r"[ \t\r\f\v]+", " ", s).strip()


def _normalize_block(s: str, max_chars: int = 8000) -> str:
    """Single spaces; preserve paragraph breaks for long DB text fields."""
    s = re.sub(r"[ \t]+", " ", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    s = s.strip()
    if len(s) > max_chars:
        s = s[: max_chars - 3].rstrip() + "..."
    return s


def _event_name_from_pdf_url(url: str) -> str | None:
    """Derive e.g. 'Chinese Grand Prix' from decision-document filename."""
    path = unquote(urlparse(url).path)
    stem = Path(path).stem.lower().replace("-", "_")
    parts = [p for p in stem.split("_") if p]
    try:
        gi = parts.index("grand")
        if gi + 1 < len(parts) and parts[gi + 1] == "prix" and gi >= 1:
            # leading token is usually season year
            event_parts = parts[1:gi]
            if event_parts:
                return " ".join(w.capitalize() for w in event_parts) + " Grand Prix"
    except ValueError:
        pass
    return None


def _event_name_from_listing_title(listing_title: str) -> str | None:
    """Match '… Chinese Grand Prix …' style text from anchor."""
    m = re.search(
        r"\b([A-Za-z][A-Za-z\s'-]{2,50}Grand Prix)\b",
        listing_title,
        re.I,
    )
    if m:
        return _collapse_ws(m.group(1))
    return None


def _event_name_from_pdf_header(text: str) -> str | None:
    """Top of document: '2026 CHINESE GRAND PRIX' or mixed-case title line."""
    head = "\n".join(text.splitlines()[:45])
    m = re.search(
        r"(?im)^\s*(\d{4}\s+)?([A-Z0-9][A-Z0-9\s'-]{3,70}GRAND\s+PRIX)\s*$",
        head,
    )
    if m:
        raw = m.group(2).strip()
        words = raw.lower().split()
        titled = " ".join(w.capitalize() for w in words)
        return titled
    m2 = re.search(
        r"\b(\d{4}\s+)?([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\s+Grand Prix)\b",
        head[:2500],
    )
    if m2:
        return m2.group(2).strip()
    return None


def _resolve_event_name(
    pdf_text: str,
    pdf_url: str,
    listing_title: str | None,
) -> str | None:
    for fn in (
        lambda: _event_name_from_pdf_header(pdf_text),
        lambda: _event_name_from_pdf_url(pdf_url),
        lambda: _event_name_from_listing_title(listing_title or ""),
    ):
        name = fn()
        if name:
            return name
    return None


def _try_parse_incident_time_to_iso(fragment: str) -> str | None:
    """Return UTC ISO-8601 string or None. Assumes CET/CEST for naive EU datetimes."""
    fragment = fragment.strip()
    if not fragment:
        return None

    iso_m = re.search(
        r"\b(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(?::\d{2})?(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?)\b",
        fragment,
        re.I,
    )
    if iso_m:
        s = iso_m.group(1).strip().replace(" ", "T")
        try:
            if s.endswith("Z"):
                dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
            elif re.search(r"[+-]\d{2}:?\d{2}$", s):
                norm = re.sub(r"([+-])(\d{2})(\d{2})$", r"\1\2:\3", s)
                dt = datetime.fromisoformat(norm)
            else:
                core = s[:19] if len(s) >= 19 else s
                dt = datetime.fromisoformat(core)
                if dt.tzinfo is None and ZoneInfo is not None:
                    dt = dt.replace(tzinfo=ZoneInfo("Europe/Paris"))
                elif dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
            return dt.astimezone(timezone.utc).isoformat()
        except ValueError:
            pass

    eu_m = re.search(
        r"\b(\d{1,2})\.(\d{1,2})\.(\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\b",
        fragment,
    )
    if eu_m and ZoneInfo is not None:
        d, mo, y, h, mi, se = eu_m.groups()
        yi = int(y)
        if yi < 100:
            yi += 2000
        try:
            dt = datetime(
                yi,
                int(mo),
                int(d),
                int(h),
                int(mi),
                int(se) if se else 0,
                tzinfo=ZoneInfo("Europe/Paris"),
            )
            return dt.astimezone(timezone.utc).isoformat()
        except ValueError:
            pass

    # "14 March 2026 09:30" / "14 March 2026 at 09:30"
    long_m = re.search(
        r"\b(\d{1,2})\s+([A-Za-z]{3,12})\s+(\d{4})\s+(?:at\s+)?(\d{1,2}):(\d{2})(?::(\d{2}))?\b",
        fragment,
        re.I,
    )
    if long_m and ZoneInfo is not None:
        d_s, mon_s, y_s, h_s, mi_s, se_s = long_m.groups()
        mon_full = mon_s.strip().title()
        t_with_s = f"{h_s}:{mi_s}:{se_s or '00'}"
        t_no_s = f"{h_s}:{mi_s}"
        dt_naive: datetime | None = None
        for fmt, tpart in (
            ("%d %B %Y %H:%M:%S", t_with_s),
            ("%d %b %Y %H:%M:%S", t_with_s),
            ("%d %B %Y %H:%M", t_no_s),
            ("%d %b %Y %H:%M", t_no_s),
        ):
            if "%S" in fmt and not se_s:
                continue
            try:
                dt_naive = datetime.strptime(
                    f"{int(d_s)} {mon_full} {y_s} {tpart}",
                    fmt,
                )
                break
            except ValueError:
                continue
        if dt_naive is not None:
            dt = dt_naive.replace(tzinfo=ZoneInfo("Europe/Paris"))
            return dt.astimezone(timezone.utc).isoformat()

    return None


def _extract_incident_time(text: str) -> str | None:
    """
    Timestamp of the incident: prefer labelled lines, then common patterns.
    Stored as UTC ISO-8601 when parseable, else concise raw text.
    """
    for labels in (
        ("Time of infringement",),
        ("Time of Incident", "Time of incident"),
        ("Date and Time", "Date and time", "Date / Time", "Date/Time"),
        ("Time",),
    ):
        raw = _line_after_label(text[:8000], labels, max_len=200)
        if raw:
            iso = _try_parse_incident_time_to_iso(raw)
            if iso:
                return iso
            cleaned = _collapse_ws(raw)
            if len(cleaned) > 180:
                cleaned = cleaned[:177] + "..."
            return cleaned or None

    for pat in (
        r"\b(\d{1,2}\.\d{1,2}\.\d{4}\s+\d{1,2}:\d{2}(?::\d{2})?)\s*(?:CET|CEST|UTC)?\b",
        r"\b(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}(?::\d{2})?)\b",
    ):
        m = re.search(pat, text[:8000], re.I)
        if m:
            candidate = m.group(1)
            iso = _try_parse_incident_time_to_iso(candidate)
            return iso or candidate
    return None


def _extract_full_text(pdf_bytes: bytes) -> str:
    parts: list[str] = []
    with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
        for page in pdf.pages:
            t = page.extract_text() or ""
            if t.strip():
                parts.append(t.strip())
    return "\n\n".join(parts)


def _doc_number_from_text(text: str) -> int | None:
    best: int | None = None
    for m in PDF_DOC_NUM_RE.finditer(text[:4000]):
        try:
            n = int(m.group(1))
        except ValueError:
            continue
        best = max(best or 0, n)
    return best


def _line_after_label(text: str, labels: tuple[str, ...], max_len: int = 500) -> str | None:
    """First line value after a line that starts with one of the labels."""
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    for i, ln in enumerate(lines):
        low = ln.lower()
        for lab in labels:
            if low.startswith(lab.lower()) and ":" in ln:
                rest = ln.split(":", 1)[1].strip()
                if rest:
                    return _collapse_ws(rest)[:max_len]
                if i + 1 < len(lines):
                    return _collapse_ws(lines[i + 1])[:max_len]
    return None


def _block_between(
    text: str,
    start_names: tuple[str, ...],
    end_names: tuple[str, ...],
    max_chars: int = 8000,
) -> str | None:
    """
    Slice from the first occurrence of any start header (line-start) to the
    first occurrence of any end header after that.
    """
    low_full = text.lower()
    starts: list[tuple[int, str]] = []
    for name in start_names:
        for m in re.finditer(
            rf"(?im)^\s*{re.escape(name)}\s*:?\s*$",
            text,
        ):
            starts.append((m.end(), name))
        for m in re.finditer(
            rf"(?im)^\s*{re.escape(name)}\s*:",
            text,
        ):
            starts.append((m.end(), name))
    if not starts:
        # Fallback: substring after first literal header line
        for name in start_names:
            idx = low_full.find(name.lower())
            if idx != -1:
                line_end = text.find("\n", idx)
                starts.append((line_end + 1 if line_end != -1 else idx + len(name), name))
                break
    if not starts:
        return None
    start_pos = min(s[0] for s in starts)

    end_pos = len(text)
    for name in end_names:
        for m in re.finditer(
            rf"(?im)^\s*{re.escape(name)}\s*:?\s*$",
            text[start_pos:],
        ):
            end_pos = min(end_pos, start_pos + m.start())
            break
        for m in re.finditer(
            rf"(?im)^\s*{re.escape(name)}\s*:",
            text[start_pos:],
        ):
            end_pos = min(end_pos, start_pos + m.start())
            break

    block = text[start_pos:end_pos].strip()
    if not block:
        return None
    return _normalize_block(block, max_chars=max_chars)


def parse_infringement_pdf(
    pdf_bytes: bytes,
    link_meta: InfringementLink,
) -> InfringementRecord:
    text = _extract_full_text(pdf_bytes)
    if not text.strip():
        raise ValueError("Empty PDF text")

    pdf_doc = _doc_number_from_text(text)
    listed = link_meta.doc_number if link_meta.doc_number > 0 else None
    doc_candidates = [n for n in (listed, pdf_doc) if n is not None and n > 0]
    final_doc_num: int | None = max(doc_candidates) if doc_candidates else None

    event_name = _resolve_event_name(text, link_meta.url, link_meta.listing_title)
    incident_time = _extract_incident_time(text)

    driver = _line_after_label(
        text[:3500],
        ("Driver", "DRIVER", "Competitor", "COMPETITOR"),
        max_len=400,
    )
    team = _line_after_label(
        text[:3500],
        ("Team", "TEAM", "Competitor Team", "Constructor"),
        max_len=400,
    )
    driver_team: str | None = None
    if driver and team:
        driver_team = f"{driver} — {team}"
    elif driver:
        driver_team = driver
    elif team:
        driver_team = team
    else:
        # Header table: "Car 12  Driver Name  Team Name" — best-effort line scan
        for ln in text.splitlines()[:25]:
            if re.search(r"\b(car|no\.?)\s*\d+", ln, re.I) and len(ln) > 10:
                driver_team = _collapse_ws(ln)[:500]
                break

    session = _line_after_label(
        text[:4000],
        ("Session", "SESSION", "Event Session"),
        max_len=200,
    )
    if not session:
        for pat in (
            r"\b(Qualifying|Sprint Qualifying|Race|Sprint|Free Practice \d+|FP\d)\b",
        ):
            m = re.search(pat, text[:3000], re.I)
            if m:
                session = m.group(1)
                break

    fact = _block_between(
        text,
        ("Statement of Fact", "Facts", "Fact", "Alleged breach", "Alleged Breach"),
        (
            "Infringement",
            "Breaches",
            "Breach",
            "Decision",
            "Conclusion",
        ),
    )
    if not fact:
        fact = _block_between(
            text,
            ("The facts are as follows", "Facts are as follows"),
            ("Infringement", "Decision", "Breaches"),
        )

    infringement = _block_between(
        text,
        ("Infringement", "Breaches", "Breach of the regulations", "Breach"),
        ("Decision", "Reasons", "Reason", "Sanction"),
    )

    decision = _block_between(
        text,
        ("Decision", "DECISION", "Sanction", "Penalties", "Penalty"),
        ("Reasons", "Reason", "Motivation", "Explanation"),
    )

    reason = _block_between(
        text,
        ("Reasons", "Reason", "Reason for decision", "Motivation", "Explanation"),
        tuple(),  # to end
    )
    if not reason:
        # Often the longest trailing section after "Decision"
        d_idx = text.lower().rfind("\ndecision")
        if d_idx == -1:
            d_idx = text.lower().rfind("decision\n")
        if d_idx != -1 and d_idx < len(text) - 50:
            tail = text[d_idx + 10 :].strip()
            if len(tail) > len(decision or ""):
                reason = _normalize_block(tail, max_chars=8000)

    return InfringementRecord(
        fia_pdf_url=link_meta.url,
        fia_doc_number=final_doc_num,
        listing_title=link_meta.listing_title,
        list_published_at=link_meta.published_at,
        event_name=event_name,
        incident_time=incident_time,
        driver_and_team=driver_team,
        session_name=session,
        fact=fact,
        infringement_rule=infringement,
        decision=decision,
        reason=reason,
    )


def connect_db(dsn: str) -> Any:
    lower = dsn.lower()
    if "sslmode=" not in lower:
        sep = "&" if "?" in dsn else "?"
        dsn = f"{dsn}{sep}sslmode=require"
    return psycopg2.connect(dsn)


UPSERT_SQL = """
INSERT INTO public.fia_infringements (
    fia_pdf_url,
    fia_doc_number,
    listing_title,
    list_published_at,
    event_name,
    incident_time,
    driver_and_team,
    session_name,
    fact,
    infringement_rule,
    decision,
    reason,
    updated_at
) VALUES (
    %(fia_pdf_url)s,
    %(fia_doc_number)s,
    %(listing_title)s,
    %(list_published_at)s,
    %(event_name)s,
    %(incident_time)s,
    %(driver_and_team)s,
    %(session_name)s,
    %(fact)s,
    %(infringement_rule)s,
    %(decision)s,
    %(reason)s,
    %(updated_at)s
)
ON CONFLICT (fia_pdf_url)
DO UPDATE SET
    fia_doc_number = EXCLUDED.fia_doc_number,
    listing_title = EXCLUDED.listing_title,
    list_published_at = EXCLUDED.list_published_at,
    event_name = EXCLUDED.event_name,
    incident_time = EXCLUDED.incident_time,
    driver_and_team = EXCLUDED.driver_and_team,
    session_name = EXCLUDED.session_name,
    fact = EXCLUDED.fact,
    infringement_rule = EXCLUDED.infringement_rule,
    decision = EXCLUDED.decision,
    reason = EXCLUDED.reason,
    updated_at = EXCLUDED.updated_at
"""


def upsert_record(conn: Any, rec: InfringementRecord) -> None:
    now = datetime.now(timezone.utc)
    payload = {
        "fia_pdf_url": rec.fia_pdf_url,
        "fia_doc_number": rec.fia_doc_number,
        "listing_title": rec.listing_title,
        "list_published_at": rec.list_published_at,
        "event_name": rec.event_name,
        "incident_time": rec.incident_time,
        "driver_and_team": rec.driver_and_team,
        "session_name": rec.session_name,
        "fact": rec.fact,
        "infringement_rule": rec.infringement_rule,
        "decision": rec.decision,
        "reason": rec.reason,
        "updated_at": now,
    }
    with conn.cursor() as cur:
        cur.execute(UPSERT_SQL, payload)
    conn.commit()


def main() -> int:
    dsn = os.environ.get("DATABASE_URL")
    if not dsn:
        log.error("DATABASE_URL is not set")
        return 1

    season_url = os.environ.get("FIA_SEASON_URL", DEFAULT_FIA_SEASON_URL)
    max_pdfs_env = os.environ.get("FIA_INFRINGEMENT_MAX_PDFS", "").strip()
    max_pdfs: int | None = None
    if max_pdfs_env:
        try:
            max_pdfs = max(1, int(max_pdfs_env))
        except ValueError:
            log.warning("Ignoring invalid FIA_INFRINGEMENT_MAX_PDFS=%r", max_pdfs_env)

    http = create_fia_session()
    warm_up_fia_session(http)

    log.info("Fetching %s", season_url)
    try:
        html = fetch_season_html(season_url, http)
    except requests.RequestException as e:
        log.error("Season page request failed: %s", e)
        return 1

    pause = random.uniform(DELAY_AFTER_LISTING_MIN, DELAY_AFTER_LISTING_MAX)
    log.info("Pausing %.2fs before PDF downloads", pause)
    time.sleep(pause)

    base = f"{urlparse(season_url).scheme}://{urlparse(season_url).netloc}"
    links = find_infringement_pdf_links(html, base)
    if not links:
        log.warning("No Infringement PDF links found")
        return 0

    if max_pdfs is not None:
        links = links[:max_pdfs]
    log.info("Processing %d infringement PDF(s)", len(links))

    try:
        conn = connect_db(dsn)
    except psycopg2.Error as e:
        log.error("Database connection failed: %s", e)
        return 1

    ok = 0
    failed = 0
    try:
        for i, link in enumerate(links):
            try:
                if i > 0:
                    gap = random.uniform(DELAY_BETWEEN_PDFS_MIN, DELAY_BETWEEN_PDFS_MAX)
                    time.sleep(gap)
                pdf_bytes = download_pdf(link.url, http)
                rec = parse_infringement_pdf(pdf_bytes, link)
                upsert_record(conn, rec)
                ok += 1
                log.info("Upserted %s", link.url)
            except Exception as e:
                failed += 1
                log.error(
                    "Skipping PDF after error url=%s err=%s",
                    link.url,
                    e,
                )
                log.debug(traceback.format_exc())
                try:
                    conn.rollback()
                except psycopg2.Error:
                    pass
    finally:
        conn.close()

    log.info("Finished: %d ok, %d failed", ok, failed)
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
