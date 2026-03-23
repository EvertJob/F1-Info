-- One-time fix: https://www.formula1.com/en/results.xml returns 404.
-- Replaces that URL inside jsonb arrays and updates the column default.

UPDATE public.profiles
SET news_feeds = (
  SELECT COALESCE(      
    jsonb_agg(
      CASE
        WHEN elem = to_jsonb('https://www.formula1.com/en/results.xml'::text)
        THEN to_jsonb('https://www.formula1.com/en/latest/all.xml'::text)
        ELSE elem
      END
    ),
    '[]'::jsonb
  )
  FROM jsonb_array_elements(news_feeds) AS t(elem)
)
WHERE news_feeds @> '["https://www.formula1.com/en/results.xml"]'::jsonb;

-- /en/all.xml is 404; same fix as above.
UPDATE public.profiles
SET news_feeds = (
  SELECT COALESCE(
    jsonb_agg(
      CASE
        WHEN elem = to_jsonb('https://www.formula1.com/en/all.xml'::text)
        THEN to_jsonb('https://www.formula1.com/en/latest/all.xml'::text)
        ELSE elem
      END
    ),
    '[]'::jsonb
  )
  FROM jsonb_array_elements(news_feeds) AS t(elem)
)
WHERE news_feeds @> '["https://www.formula1.com/en/all.xml"]'::jsonb;

ALTER TABLE public.profiles
  ALTER COLUMN news_feeds
  SET DEFAULT '["https://www.formula1.com/en/latest/all.xml"]'::jsonb;
