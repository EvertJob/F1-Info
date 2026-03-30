-- Championship simulator: per-user predictions and optional scenarios.
-- Run in Supabase SQL editor after review. RLS: users manage own rows.

create table if not exists public.user_predictions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  circuit_id text not null,
  season_year int not null default 2026,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (user_id, circuit_id, season_year)
);

create table if not exists public.user_scenarios (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  season_year int not null default 2026,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create index if not exists idx_user_predictions_user
  on public.user_predictions (user_id, season_year);

create index if not exists idx_user_scenarios_user
  on public.user_scenarios (user_id, season_year);

alter table public.user_predictions enable row level security;
alter table public.user_scenarios enable row level security;

-- Idempotent: safe to re-run after a partial apply (42710 if policy already exists).
drop policy if exists "Users read own predictions" on public.user_predictions;
create policy "Users read own predictions"
  on public.user_predictions for select
  using (auth.uid() = user_id);

drop policy if exists "Users upsert own predictions" on public.user_predictions;
create policy "Users upsert own predictions"
  on public.user_predictions for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users update own predictions" on public.user_predictions;
create policy "Users update own predictions"
  on public.user_predictions for update
  using (auth.uid() = user_id);

drop policy if exists "Users delete own predictions" on public.user_predictions;
create policy "Users delete own predictions"
  on public.user_predictions for delete
  using (auth.uid() = user_id);

drop policy if exists "Users read own scenarios" on public.user_scenarios;
create policy "Users read own scenarios"
  on public.user_scenarios for select
  using (auth.uid() = user_id);

drop policy if exists "Users insert own scenarios" on public.user_scenarios;
create policy "Users insert own scenarios"
  on public.user_scenarios for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users update own scenarios" on public.user_scenarios;
create policy "Users update own scenarios"
  on public.user_scenarios for update
  using (auth.uid() = user_id);

drop policy if exists "Users delete own scenarios" on public.user_scenarios;
create policy "Users delete own scenarios"
  on public.user_scenarios for delete
  using (auth.uid() = user_id);

-- Optional: public read for shared links (e.g. username lookup) — add via
-- security-definer RPC or a dedicated `public_prediction_shares` table.

-- If upserts fail with "Could not find the 'payload' column", the table predates
-- this file: run fix_user_predictions_payload_column.sql once.
-- If upserts fail with 42P10 / ON CONFLICT: run fix_user_predictions_unique_for_upsert.sql
