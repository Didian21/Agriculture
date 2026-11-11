-- =========================================================
-- ROW LEVEL SECURITY (RLS) POLICIES FOR ML & PREDICTION TABLES
-- Tables: price_forecasts, model_metrics, yield_estimates, planting_advisory
-- =========================================================

-- 1. Enable RLS on ML tables
alter table if exists public.price_forecasts enable row level security;
alter table if exists public.model_metrics enable row level security;
alter table if exists public.yield_estimates enable row level security;
alter table if exists public.planting_advisory enable row level security;

-- 2. Drop existing policies to prevent conflicts
drop policy if exists "Allow public read/write price_forecasts" on public.price_forecasts;
drop policy if exists "Allow public read/write model_metrics" on public.model_metrics;
drop policy if exists "Allow public read/write yield_estimates" on public.yield_estimates;
drop policy if exists "Allow public read/write planting_advisory" on public.planting_advisory;

-- 3. Create public RLS policies
create policy "Allow public read/write price_forecasts" on public.price_forecasts for all using (true) with check (true);
create policy "Allow public read/write model_metrics" on public.model_metrics for all using (true) with check (true);
create policy "Allow public read/write yield_estimates" on public.yield_estimates for all using (true) with check (true);
create policy "Allow public read/write planting_advisory" on public.planting_advisory for all using (true) with check (true);
