-- =========================================================
-- SUPABASE SCHEMA UPDATE: ADD LANDOWNER / EMPLOYER COLUMNS
-- =========================================================

-- 1. Add landowner / employer columns to farms table
ALTER TABLE public.farms
ADD COLUMN IF NOT EXISTS landowner_id text NULL,
ADD COLUMN IF NOT EXISTS landowner_name text NULL;

-- 2. Add employer_name column to farmers table
ALTER TABLE public.farmers
ADD COLUMN IF NOT EXISTS employer_name text NULL;
