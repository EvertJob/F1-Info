-- One JSONB column for expand/collapse state on circuit, driver, and team detail screens.
-- Shape: { "circuit": { "weather_forecast": true, ... }, "driver": { ... }, "team": { ... } }

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS detail_expansion_prefs jsonb NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.profiles.detail_expansion_prefs IS
  'Nested map: category (circuit|driver|team) -> sectionId -> expanded bool. App-owned section ids.';
