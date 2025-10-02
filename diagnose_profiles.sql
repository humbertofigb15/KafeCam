-- Diagnostic queries to identify profile data issues

-- 1. Check for profiles with missing critical data
SELECT 
  'Profiles with missing data' as check_type,
  COUNT(*) as count
FROM public.profiles
WHERE name IS NULL OR name = '' 
   OR phone IS NULL OR phone = '';

-- 2. Show profiles with missing data (detailed)
SELECT 
  id,
  name,
  phone,
  email,
  organization,
  role,
  created_at,
  CASE 
    WHEN name IS NULL OR name = '' THEN 'Missing name'
    WHEN phone IS NULL OR phone = '' THEN 'Missing phone'
    ELSE 'OK'
  END as issue
FROM public.profiles
WHERE name IS NULL OR name = '' 
   OR phone IS NULL OR phone = ''
ORDER BY created_at DESC;

-- 3. Check auth.users metadata for these profiles
SELECT 
  u.id,
  u.email as auth_email,
  u.raw_user_meta_data->>'name' as meta_name,
  u.raw_user_meta_data->>'phone' as meta_phone,
  u.raw_user_meta_data->>'email' as meta_email,
  u.raw_user_meta_data->>'organization' as meta_org,
  p.name as profile_name,
  p.phone as profile_phone,
  p.email as profile_email
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE p.name IS NULL OR p.name = '' 
   OR p.phone IS NULL OR p.phone = ''
ORDER BY u.created_at DESC;

-- 4. Show all profiles with their auth.users data for comparison
SELECT 
  u.id,
  u.email as auth_email,
  SPLIT_PART(u.email, '@', 1) as extracted_phone,
  u.raw_user_meta_data as metadata,
  p.name,
  p.phone,
  p.email as profile_email,
  p.organization,
  p.role
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.email LIKE '%@kafe.local'
ORDER BY u.created_at DESC
LIMIT 20;

-- 5. Fix a specific user's profile (replace the UUID)
-- UPDATE public.profiles
-- SET 
--   name = 'User Name Here',
--   phone = '1234567890',
--   email = 'user@example.com',
--   organization = 'Kaapeh'
-- WHERE id = 'YOUR-USER-UUID-HERE';

-- 6. Quick fix for all profiles missing phone but having kafe.local email
UPDATE public.profiles p
SET phone = SPLIT_PART(u.email, '@', 1)
FROM auth.users u
WHERE p.id = u.id
  AND u.email LIKE '%@kafe.local'
  AND (p.phone IS NULL OR p.phone = '')
RETURNING p.id, p.name, p.phone;

-- 7. Show current session user's profile (if you know the UUID)
-- Replace with actual session UUID from app logs
-- SELECT * FROM public.profiles WHERE id = 'YOUR-SESSION-UUID';
