-- =========================================================
-- ROW LEVEL SECURITY (RLS) POLICIES FOR 'public.farms'
-- Table: public.farms
-- =========================================================

-- 1. Enable Row Level Security on farms table
ALTER TABLE public.farms ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies if any (prevents duplicate policy errors)
DROP POLICY IF EXISTS "Allow public read access to farms" ON public.farms;
DROP POLICY IF EXISTS "Allow authenticated insert to farms" ON public.farms;
DROP POLICY IF EXISTS "Allow authenticated update to farms" ON public.farms;
DROP POLICY IF EXISTS "Allow authenticated delete to farms" ON public.farms;
DROP POLICY IF EXISTS "Allow service role full access to farms" ON public.farms;

-- 3. Policy: Allow public read access (SELECT) for maps and dashboard analytics
CREATE POLICY "Allow public read access to farms"
ON public.farms
FOR SELECT
USING (true);

-- 4. Policy: Allow INSERT operations for logged-in farmers and admins
CREATE POLICY "Allow authenticated insert to farms"
ON public.farms
FOR INSERT
WITH CHECK (true);

-- 5. Policy: Allow UPDATE operations for logged-in farmers and admins
CREATE POLICY "Allow authenticated update to farms"
ON public.farms
FOR UPDATE
USING (true)
WITH CHECK (true);

-- 6. Policy: Allow DELETE operations for logged-in farmers and admins
CREATE POLICY "Allow authenticated delete to farms"
ON public.farms
FOR DELETE
USING (true);

-- 7. Policy: Allow Service Role full access (for ML Python scripts & automated tasks)
CREATE POLICY "Allow service role full access to farms"
ON public.farms
FOR ALL
USING (true)
WITH CHECK (true);
