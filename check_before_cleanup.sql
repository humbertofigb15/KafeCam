-- CHECK WHAT POLICIES EXIST BEFORE CLEANUP
-- Run this to see what will be deleted

-- 1. List ALL storage policies for avatars and captures
SELECT 
    'STORAGE POLICIES TO BE DELETED:' as section;
    
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN qual IS NULL AND with_check IS NULL THEN 'NO CONDITIONS (BROKEN!)'
        WHEN qual IS NULL THEN 'INSERT WITH CHECK'
        ELSE 'HAS USING CONDITION'
    END as status
FROM pg_policies 
WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND (policyname LIKE '%avatar%' OR policyname LIKE '%capture%')
ORDER BY policyname;

-- 2. List ALL table policies for captures
SELECT 
    'TABLE POLICIES TO BE DELETED:' as section;

SELECT 
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'captures'
ORDER BY policyname;

-- 3. Show duplicates
SELECT 
    'DUPLICATE POLICIES:' as section;

WITH policy_counts AS (
    SELECT 
        policyname,
        COUNT(*) as count
    FROM pg_policies 
    WHERE schemaname IN ('storage', 'public')
        AND (policyname LIKE '%avatar%' OR policyname LIKE '%capture%')
    GROUP BY policyname
)
SELECT * FROM policy_counts WHERE count > 1;

-- 4. Policies with NULL conditions (these are broken)
SELECT 
    'BROKEN POLICIES (NULL conditions):' as section;

SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    'NULL qual and with_check' as issue
FROM pg_policies 
WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND (policyname LIKE '%avatar%' OR policyname LIKE '%capture%')
    AND qual IS NULL 
    AND with_check IS NULL;

-- 5. Summary
SELECT 
    'SUMMARY:' as section;

SELECT 
    'Total Storage Policies' as type,
    COUNT(*) as count,
    COUNT(CASE WHEN qual IS NULL AND with_check IS NULL THEN 1 END) as broken_count
FROM pg_policies 
WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND (policyname LIKE '%avatar%' OR policyname LIKE '%capture%')
UNION ALL
SELECT 
    'Total Table Policies' as type,
    COUNT(*) as count,
    0 as broken_count
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'captures';

-- 6. What the cleanup will do
SELECT 
    'AFTER CLEANUP YOU WILL HAVE:' as section,
    '4 avatar policies (read, write, update, remove)' as avatars,
    '4 capture storage policies (read, write, update, remove)' as captures_storage,
    '4 capture table policies (insert, read, update, remove)' as captures_table;
