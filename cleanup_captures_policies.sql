-- CLEANUP DUPLICATE CAPTURE POLICIES
-- Remove all the duplicate and conflicting policies, keeping only the essential ones

-- 1. Drop ALL existing policies to start fresh
DROP POLICY IF EXISTS "captures owner insert" ON public.captures;
DROP POLICY IF EXISTS "captures owner update" ON public.captures;
DROP POLICY IF EXISTS "captures read owner_or_staff" ON public.captures;
DROP POLICY IF EXISTS "captures_insert_own" ON public.captures;
DROP POLICY IF EXISTS "captures_select_all" ON public.captures;
DROP POLICY IF EXISTS "captures_update_own" ON public.captures;
DROP POLICY IF EXISTS "captures_delete_own" ON public.captures;
DROP POLICY IF EXISTS "captures insert" ON public.captures;
DROP POLICY IF EXISTS "captures update" ON public.captures;
DROP POLICY IF EXISTS "captures delete" ON public.captures;
DROP POLICY IF EXISTS "captures_read_owner_or_tech" ON public.captures;
DROP POLICY IF EXISTS "captures_select_self" ON public.captures;
DROP POLICY IF EXISTS "captures_insert_self" ON public.captures;

-- 2. Create only the necessary policies
-- Allow users to insert their own captures
CREATE POLICY "captures_insert_own"
ON public.captures 
FOR INSERT
TO authenticated
WITH CHECK (uploaded_by_user_id = auth.uid());

-- Allow all authenticated users to read all captures
CREATE POLICY "captures_select_all"
ON public.captures 
FOR SELECT
TO authenticated
USING (true);

-- Allow users to update their own captures
CREATE POLICY "captures_update_own"
ON public.captures 
FOR UPDATE
TO authenticated
USING (uploaded_by_user_id = auth.uid())
WITH CHECK (uploaded_by_user_id = auth.uid());

-- Allow users to delete their own captures
CREATE POLICY "captures_delete_own"
ON public.captures 
FOR DELETE
TO authenticated
USING (uploaded_by_user_id = auth.uid());

-- 3. Verify final policies
SELECT 'Final policies for captures table:' as info;
SELECT policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'captures'
ORDER BY policyname;
