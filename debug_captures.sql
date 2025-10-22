-- Debug captures storage issue
-- Run this in Supabase SQL Editor to check what's happening

-- 1. Check if captures table has any data
SELECT COUNT(*) as total_captures FROM public.captures;

-- 2. Check recent captures (last 10)
SELECT 
    id,
    plot_id,
    taken_at,
    photo_key,
    uploaded_by_user_id,
    created_at
FROM public.captures
ORDER BY created_at DESC
LIMIT 10;

-- 3. Check storage bucket policies for captures
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname LIKE '%captures%';

-- 4. Check if there are any objects in the captures bucket
SELECT 
    COUNT(*) as total_objects,
    COUNT(DISTINCT SPLIT_PART(name, '/', 1)) as total_folders
FROM storage.objects
WHERE bucket_id = 'captures';

-- 5. List first 10 objects in captures bucket
SELECT 
    id,
    name,
    created_at,
    updated_at
FROM storage.objects
WHERE bucket_id = 'captures'
ORDER BY created_at DESC
LIMIT 10;

-- 6. Check if the captures bucket exists and is configured correctly
SELECT 
    id,
    name,
    public,
    created_at
FROM storage.buckets
WHERE name = 'captures';

-- 7. Test if authenticated users can insert into captures table
-- This simulates what the app tries to do
-- Replace 'YOUR_USER_ID' with an actual user ID from auth.users
/*
INSERT INTO public.captures (
    plot_id,
    taken_at,
    photo_key,
    uploaded_by_user_id,
    device_model
) VALUES (
    gen_random_uuid(), -- random plot_id for testing
    NOW(),
    'test_folder/test_image.jpg',
    'YOUR_USER_ID'::uuid,
    'Test Device'
) RETURNING *;
*/

-- 8. Check if there are any errors in the storage logs
-- Note: This might not be available depending on your Supabase plan
/*
SELECT 
    created_at,
    method,
    status,
    error_message
FROM storage.logs
WHERE bucket = 'captures'
    AND created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 20;
*/
