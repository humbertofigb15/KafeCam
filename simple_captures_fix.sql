-- SIMPLE FIX FOR CAPTURES
-- Only adds missing policies for the public.captures table

-- 1. Enable RLS on captures table if not already enabled
ALTER TABLE public.captures ENABLE ROW LEVEL SECURITY;

-- 2. Create policies for public.captures table
-- Drop any existing policies first to avoid conflicts
DROP POLICY IF EXISTS "captures_insert_own" ON public.captures;
DROP POLICY IF EXISTS "captures_select_all" ON public.captures;
DROP POLICY IF EXISTS "captures_update_own" ON public.captures;
DROP POLICY IF EXISTS "captures_delete_own" ON public.captures;

-- Allow users to insert their own captures
-- Cast UUID to text since uploaded_by_user_id column is text
CREATE POLICY "captures_insert_own"
ON public.captures FOR INSERT
TO authenticated
WITH CHECK (uploaded_by_user_id = (auth.uid())::text);

-- Allow users to read all captures
CREATE POLICY "captures_select_all"
ON public.captures FOR SELECT
TO authenticated
USING (true);

-- Allow users to update their own captures
CREATE POLICY "captures_update_own"
ON public.captures FOR UPDATE
TO authenticated
USING (uploaded_by_user_id = (auth.uid())::text)
WITH CHECK (uploaded_by_user_id = (auth.uid())::text);

-- Allow users to delete their own captures
CREATE POLICY "captures_delete_own"
ON public.captures FOR DELETE
TO authenticated
USING (uploaded_by_user_id = (auth.uid())::text);

-- 3. Verify the policies were created
SELECT 'Table policies created:' as info;
SELECT policyname, cmd, permissive
FROM pg_policies
WHERE schemaname = 'public' 
AND tablename = 'captures'
ORDER BY policyname;
