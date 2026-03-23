-- UI display preferences (Simplicity / compact / motion) for logged-in users.
-- Single JSONB object; extend with new keys in app + migrations when needed (merge defaults in Dart).

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS display_settings jsonb
  NOT NULL
  DEFAULT '{"ui_mode": "standard", "compact": false, "motion_reduced": false}'::jsonb;

-- Safety net: if the column ever existed as nullable or was partially migrated, normalize nulls.
UPDATE public.profiles
SET display_settings = '{"ui_mode": "standard", "compact": false, "motion_reduced": false}'::jsonb
WHERE display_settings IS NULL;

COMMENT ON COLUMN public.profiles.display_settings IS
  'JSON: ui_mode (standard|…), compact (bool), motion_reduced (bool). App merges unknown/missing keys to defaults.';
