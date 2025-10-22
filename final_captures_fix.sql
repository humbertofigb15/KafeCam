-- FINAL FIX FOR CAPTURES TABLE
-- First, let's check the column type
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'captures' 
AND column_name = 'uploaded_by_user_id';

-- Enable RLS
ALTER TABLE public.captures ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "captures_insert_own" ON public.captures;
DROP POLICY IF EXISTS "captures_select_all" ON public.captures;
DROP POLICY IF EXISTS "captures_update_own" ON public.captures;
DROP POLICY IF EXISTS "captures_delete_own" ON public.captures;

-- Create policies with proper UUID handling
-- If uploaded_by_user_id is UUID type:
CREATE POLICY "captures_insert_own"
ON public.captures 
FOR INSERT
TO authenticated
WITH CHECK (uploaded_by_user_id = auth.uid());

CREATE POLICY "captures_select_all"
ON public.captures 
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "captures_update_own"
ON public.captures 
FOR UPDATE
TO authenticated
USING (uploaded_by_user_id = auth.uid())
WITH CHECK (uploaded_by_user_id = auth.uid());

CREATE POLICY "captures_delete_own"
ON public.captures 
FOR DELETE
TO authenticated
USING (uploaded_by_user_id = auth.uid());

-- Verify
SELECT policyname, cmd 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'captures';
