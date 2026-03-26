/**
 * Merges tool/patch_{locale}.json into lib/l10n/app_{locale}.arb
 * and copies @metadata from app_en.arb. Re-sorts keys (@@locale first, then A–Z).
 *
 * Run from repo root: node tool/merge_arb_from_patches.mjs
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '..');

const en = JSON.parse(
  fs.readFileSync(path.join(root, 'lib/l10n/app_en.arb'), 'utf8'),
);

function sortArb(loc) {
  const localeTag = loc['@@locale'];
  const baseKeys = Object.keys(loc)
    .filter((k) => k !== '@@locale' && !k.startsWith('@'))
    .sort((a, b) => a.localeCompare(b));
  const out = { '@@locale': localeTag };
  for (const k of baseKeys) {
    out[k] = loc[k];
    const mk = `@${k}`;
    if (Object.prototype.hasOwnProperty.call(loc, mk)) {
      out[mk] = loc[mk];
    }
  }
  return out;
}

function mergeLocale(locale) {
  const arbPath = path.join(root, `lib/l10n/app_${locale}.arb`);
  const patchPath = path.join(root, `tool/patch_${locale}.json`);

  const loc = JSON.parse(fs.readFileSync(arbPath, 'utf8'));
  const patch = JSON.parse(fs.readFileSync(patchPath, 'utf8'));

  for (const [key, value] of Object.entries(patch)) {
    if (Object.prototype.hasOwnProperty.call(loc, key)) {
      continue;
    }
    loc[key] = value;
    const metaKey = `@${key}`;
    if (Object.prototype.hasOwnProperty.call(en, metaKey)) {
      loc[metaKey] = JSON.parse(JSON.stringify(en[metaKey]));
    }
  }

  const sorted = sortArb(loc);
  fs.writeFileSync(
    arbPath,
    `${JSON.stringify(sorted, null, 2)}\n`,
    'utf8',
  );
  console.log(`Merged ${locale}: ${Object.keys(patch).length} patch keys applied (skipped if already present)`);
}

['nl', 'de', 'fr'].forEach(mergeLocale);
