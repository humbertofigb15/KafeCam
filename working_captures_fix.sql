-- WORKING FIX FOR CAPTURES TABLE POLICIES
-- This will enable RLS and create policies for the public.captures table

-- 1. Enable RLS on captures table
ALTER TABLE public.captures ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies to start fresh
DROP POLICY IF EXISTS "captures_insert_own" ON public.captures;
DROP POLICY IF EXISTS "captures_select_all" ON public.captures;
DROP POLICY IF EXISTS "captures_update_own" ON public.captures;
DROP POLICY IF EXISTS "captures_delete_own" ON public.captures;

-- 3. Create new policies

-- Allow users to insert their own captures
CREATE POLICY "captures_insert_own"
ON public.captures 
FOR INSERT
TO authenticated
WITH CHECK (uploaded_by_user_id = (auth.uid())::text);

-- Allow users to read all captures
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
USING (uploaded_by_user_id = (auth.uid())::text)
WITH CHECK (uploaded_by_user_id = (auth.uid())::text);

-- Allow users to delete their own captures
CREATE POLICY "captures_delete_own"
ON public.captures 
FOR DELETE
TO authenticated
USING (uploaded_by_user_id = (auth.uid())::text);

-- 4. Verify
SELECT policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'captures';
