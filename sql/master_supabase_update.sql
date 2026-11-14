-- =========================================================
-- PAGRI SYSTEM: MASTER SUPABASE DATABASE UPDATE SCRIPT
-- Run this script in your Supabase SQL Editor
-- =========================================================

-- 1. UPDATE 'farms' TABLE (Add Farm Land Polygon Boundary & Landowner columns)
ALTER TABLE public.farms
ADD COLUMN IF NOT EXISTS boundary_points text NULL,
ADD COLUMN IF NOT EXISTS landowner_id text NULL,
ADD COLUMN IF NOT EXISTS landowner_name text NULL;

-- 2. UPDATE 'farmers' TABLE (Add Employer Name for Hired Farmworkers)
ALTER TABLE public.farmers
ADD COLUMN IF NOT EXISTS employer_name text NULL;

-- 3. ENABLE ROW LEVEL SECURITY (RLS) ON ALL TABLES
ALTER TABLE IF EXISTS public.farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.farmer_plantings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.market_farmgate_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.price_forecasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.model_metrics ENABLE ROW LEVEL SECURITY;

-- 4. DROP EXISTING POLICIES TO PREVENT CONFLICTS
DROP POLICY IF EXISTS "Allow full access to farms" ON public.farms;
DROP POLICY IF EXISTS "Allow full access to farmer_plantings" ON public.farmer_plantings;
DROP POLICY IF EXISTS "Allow full access to market_farmgate_prices" ON public.market_farmgate_prices;
DROP POLICY IF EXISTS "Allow full access to price_forecasts" ON public.price_forecasts;
DROP POLICY IF EXISTS "Allow full access to model_metrics" ON public.model_metrics;

-- 5. CREATE PUBLIC RLS PERMISSIONS FOR APP & ML PIPELINE
CREATE POLICY "Allow full access to farms" ON public.farms FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access to farmer_plantings" ON public.farmer_plantings FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access to market_farmgate_prices" ON public.market_farmgate_prices FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access to price_forecasts" ON public.price_forecasts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow full access to model_metrics" ON public.model_metrics FOR ALL USING (true) WITH CHECK (true);

-- =========================================================
-- SUCCESS: Database Schema & RLS Policies Updated!
-- =========================================================
