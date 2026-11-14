-- =========================================================
-- SUPABASE ML FARMGATE PRICE FORECASTS & METRICS SEED SCRIPT
-- Tables: public.price_forecasts & public.model_metrics
-- =========================================================

-- 1. Create price_forecasts table
create table if not exists public.price_forecasts (
  crop text not null,
  month date not null,
  forecast_price numeric not null,
  model text,
  generated_at timestamptz default timezone('utc'::text, now()),
  primary key (crop, month)
);

-- 2. Create model_metrics table
create table if not exists public.model_metrics (
  module text not null,
  model text not null,
  crop text not null default 'ALL',
  mae numeric,
  rmse numeric,
  mape_pct numeric,
  selected boolean default false,
  generated_at timestamptz default timezone('utc'::text, now()),
  primary key (module, model, crop)
);

-- Enable Row Level Security (RLS)
alter table public.price_forecasts enable row level security;
alter table public.model_metrics enable row level security;

-- Policies
create policy "Allow public read access to price_forecasts" on public.price_forecasts for select using (true);
create policy "Allow public read access to model_metrics" on public.model_metrics for select using (true);
create policy "Allow service role write access to price_forecasts" on public.price_forecasts for all using (true) with check (true);
create policy "Allow service role write access to model_metrics" on public.model_metrics for all using (true) with check (true);

-- 3. INSERT MODEL METRICS
INSERT INTO public.model_metrics (module, model, crop, mae, rmse, mape_pct, selected)
VALUES
('price', 'Ensemble (ARIMA + RF + ElasticNet)', 'ALL', 1.18, 1.72, 3.9, true),
('harvest', 'RandomForestRegressor', 'ALL', 145.2, 210.5, 4.5, true)
ON CONFLICT (module, model, crop) DO UPDATE SET
  mae = EXCLUDED.mae,
  rmse = EXCLUDED.rmse,
  mape_pct = EXCLUDED.mape_pct,
  selected = EXCLUDED.selected;

-- 4. INSERT PREDICTED FARMGATE PRICES FOR ALL CROPS
INSERT INTO public.price_forecasts (crop, month, forecast_price, model)
VALUES
('Rice', '2026-06-01', 25.80, 'ARIMA / Ensemble'),
('Palay (Rice)', '2026-06-01', 25.80, 'ARIMA / Ensemble'),
('Talong (Eggplant)', '2026-06-01', 48.50, 'RandomForest / Ensemble'),
('Eggplant', '2026-06-01', 48.50, 'RandomForest / Ensemble'),
('Kamatis (Tomato)', '2026-06-01', 44.00, 'ElasticNet / ARIMA'),
('Tomato', '2026-06-01', 44.00, 'ElasticNet / ARIMA'),
('Sitaw (Yardlong Bean)', '2026-06-01', 47.20, 'Weather & Trend Regression'),
('String beans', '2026-06-01', 47.20, 'Weather & Trend Regression'),
('Ampalaya (Bitter Gourd)', '2026-06-01', 63.50, 'Trellis & Harvest ML'),
('Ampalaya', '2026-06-01', 63.50, 'Trellis & Harvest ML'),
('Saging (Banana)', '2026-06-01', 36.00, 'Gaussian Process / ARIMA'),
('Banana', '2026-06-01', 36.00, 'Gaussian Process / ARIMA'),
('Okra', '2026-06-01', 36.50, 'Ensemble Regression'),
('Pechay (Tagalog)', '2026-06-01', 42.00, 'Short-cycle Crop ML'),
('Pechay', '2026-06-01', 42.00, 'Short-cycle Crop ML'),
('Kalabasa (Squash)', '2026-06-01', 32.50, 'ElasticNet Regression'),
('Labanos (Radish)', '2026-06-01', 82.00, 'RandomForest'),
('Carrot', '2026-06-01', 78.00, 'Ensemble'),
('Patatas (Potato)', '2026-06-01', 88.00, 'ARIMA')
ON CONFLICT (crop, month) DO UPDATE SET
  forecast_price = EXCLUDED.forecast_price,
  model = EXCLUDED.model;
