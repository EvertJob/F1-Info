-- Optional multi-favorites for My Paddock (JSONB arrays of driver numbers and team names).
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS favorite_drivers jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS favorite_teams jsonb NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.profiles.favorite_drivers IS
  'JSON array of driver numbers (int), e.g. [1, 33].';

COMMENT ON COLUMN public.profiles.favorite_teams IS
  'JSON array of constructor/team display strings matching standings, e.g. ["Red Bull Racing"].';
