-- =========================================================
-- SUPABASE TABLE FOR FARMER PLANTINGS & CROPS
-- Table: public.farmer_plantings
-- =========================================================

create table if not exists public.farmer_plantings (
  id text not null,
  farmer_id text null,
  farmer_name text null,
  crop text not null,
  hectares double precision not null default 1.0,
  planted_on timestamp with time zone not null default timezone ('utc'::text, now()),
  last_yield_kg double precision null,
  cost_php double precision null,
  barangay text null,
  created_at timestamp with time zone not null default timezone ('utc'::text, now()),
  constraint farmer_plantings_pkey primary key (id)
) TABLESPACE pg_default;

-- Create index for fast lookup by farmer
create index if not exists idx_fp_farmer_id on public.farmer_plantings using btree (farmer_id);
create index if not exists idx_fp_farmer_name on public.farmer_plantings using btree (farmer_name);

-- Enable Row Level Security (RLS) & Policies
alter table public.farmer_plantings enable row level security;
create policy "Allow public read access to farmer_plantings" on public.farmer_plantings for select using (true);
create policy "Allow authenticated write access to farmer_plantings" on public.farmer_plantings for all using (true) with check (true);
create policy "Allow service role write access to farmer_plantings" on public.farmer_plantings for all using (true) with check (true);
