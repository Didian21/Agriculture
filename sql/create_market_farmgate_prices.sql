-- =========================================================
-- SUPABASE TABLE FOR VEGETABLE MARKET & FARMGATE PRICES
-- Table: public.market_farmgate_prices
-- =========================================================

create table if not exists public.market_farmgate_prices (
  id text not null,
  vegetable text not null,
  farmgate_price double precision not null,
  market_price double precision not null,
  date timestamp with time zone not null,
  market_location text not null default 'Pagsanjan Public Market',
  uploaded_by text not null,
  date_uploaded timestamp with time zone not null default timezone ('utc'::text, now()),
  constraint market_farmgate_prices_pkey primary key (id)
) TABLESPACE pg_default;

-- Create index for quick lookup by vegetable and date
create index if not exists idx_mfp_veg_date on public.market_farmgate_prices using btree (vegetable, date);

-- Enable Row Level Security (RLS)
alter table public.market_farmgate_prices enable row level security;

-- Policies
create policy "Allow public read access to market_farmgate_prices" on public.market_farmgate_prices for select using (true);
create policy "Allow service role write access to market_farmgate_prices" on public.market_farmgate_prices for all using (true) with check (true);
create policy "Allow authenticated write access to market_farmgate_prices" on public.market_farmgate_prices for all using (true) with check (true);

-- SAMPLE INITIAL DATA FOR VEGETABLE MARKET & FARMGATE PRICES
INSERT INTO public.market_farmgate_prices (id, vegetable, farmgate_price, market_price, date, market_location, uploaded_by)
VALUES
('MP001', 'Talong (Eggplant)', 45.00, 70.00, NOW() - INTERVAL '1 day', 'Pagsanjan Public Market', 'Ms. Jellie Masacayan'),
('MP002', 'Kamatis (Tomato)', 50.00, 85.00, NOW() - INTERVAL '1 day', 'Pagsanjan Public Market', 'Ms. Jellie Masacayan'),
('MP003', 'Okra', 35.00, 55.00, NOW() - INTERVAL '2 days', 'Pagsanjan Public Market', 'Engr. Arnel Cruz'),
('MP004', 'Pechay (Tagalog)', 40.00, 65.00, NOW() - INTERVAL '2 days', 'Pagsanjan Public Market', 'Clara Gonzales'),
('MP005', 'Sitaw (Yardlong Bean)', 45.00, 75.00, NOW() - INTERVAL '3 days', 'Pagsanjan Public Market', 'Ms. Jellie Masacayan'),
('MP006', 'Ampalaya (Bitter Gourd)', 60.00, 90.00, NOW() - INTERVAL '3 days', 'Pagsanjan Public Market', 'Engr. Arnel Cruz')
ON CONFLICT (id) DO NOTHING;
