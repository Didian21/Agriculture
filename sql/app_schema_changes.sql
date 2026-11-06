-- =========================================================
-- SUPABASE SCHEMA FOR PAGSANJAN DSS MACHINE LEARNING RESULTS
-- =========================================================

-- 1. YIELD ESTIMATES (kg/ha predicted per crop, barangay, and month)
create table if not exists public.yield_estimates (
  crop text not null,
  barangay text not null,
  month int not null check (month between 1 and 12),
  yield_kg_ha numeric not null,
  rmse_kg_ha numeric,
  model text,
  generated_at timestamptz default now(),
  primary key (crop, barangay, month)
);

-- 2. PRICE FORECASTS (predicted PHP/kg per crop and month)
create table if not exists public.price_forecasts (
  crop text not null,
  month date not null,
  forecast_price numeric not null,
  model text,
  generated_at timestamptz default now(),
  primary key (crop, month)
);

-- 3. PLANTING ADVISORY (suitability score per crop and month)
create table if not exists public.planting_advisory (
  crop text not null,
  month int not null check (month between 1 and 12),
  score numeric not null,
  generated_at timestamptz default now(),
  primary key (crop, month)
);

-- 4. MODEL METRICS (MAE, RMSE, MAPE for model evaluation)
create table if not exists public.model_metrics (
  module text not null,
  model text not null,
  crop text not null default 'ALL',
  mae numeric,
  rmse numeric,
  mape_pct numeric,
  selected boolean default false,
  generated_at timestamptz default now(),
  primary key (module, model, crop)
);

-- ENABLE ROW LEVEL SECURITY
alter table public.yield_estimates enable row level security;
alter table public.price_forecasts enable row level security;
alter table public.planting_advisory enable row level security;
alter table public.model_metrics enable row level security;

-- READ POLICIES FOR AUTHENTICATED & ANON USERS
create policy "Allow public read access to yield_estimates" on public.yield_estimates for select using (true);
create policy "Allow public read access to price_forecasts" on public.price_forecasts for select using (true);
create policy "Allow public read access to planting_advisory" on public.planting_advisory for select using (true);
create policy "Allow public read access to model_metrics" on public.model_metrics for select using (true);

-- WRITE POLICIES FOR SERVICE ROLE
create policy "Allow service role write access to yield_estimates" on public.yield_estimates for all using (true) with check (true);
create policy "Allow service role write access to price_forecasts" on public.price_forecasts for all using (true) with check (true);
create policy "Allow service role write access to planting_advisory" on public.planting_advisory for all using (true) with check (true);
create policy "Allow service role write access to model_metrics" on public.model_metrics for all using (true) with check (true);
