-- RSS feed URLs for the in-app News tab (JSON array of strings).
-- After applying: enable Realtime for `profiles` if not already (Dashboard → Database → Replication,
-- or: ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;)

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS news_feeds jsonb
  NOT NULL
  DEFAULT '["https://www.formula1.com/en/latest/all.xml"]'::jsonb;

COMMENT ON COLUMN public.profiles.news_feeds IS
  'Ordered list of RSS/Atom feed URLs merged on the News screen.';
