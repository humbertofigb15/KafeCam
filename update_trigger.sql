-- Enhanced trigger to properly handle user metadata during signup
-- This ensures profile data is correctly populated from the app's registration form

BEGIN;

-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create improved handle_new_user function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER 
SET search_path = public
AS $$
BEGIN
  -- Extract phone from email if not in metadata (format: 1234567890@kafe.local)
  DECLARE
    extracted_phone TEXT;
  BEGIN
    -- Try to extract phone from email format
    extracted_phone := CASE 
      WHEN new.email LIKE '%@kafe.local' THEN 
        SPLIT_PART(new.email, '@', 1)
      ELSE 
        NULL
    END;
    
    -- Insert or update profile with all available data
    INSERT INTO public.profiles (
      id, 
      name, 
      email, 
      phone, 
      organization, 
      role, 
      locale
    )
    VALUES (
      new.id,
      COALESCE(
        new.raw_user_meta_data->>'name',
        new.raw_user_meta_data->>'full_name',
        ''
      ),
      COALESCE(
        NULLIF(new.raw_user_meta_data->>'email', ''),
        new.email
      ),
      COALESCE(
        new.raw_user_meta_data->>'phone',
        extracted_phone,
        ''
      ),
      COALESCE(
        new.raw_user_meta_data->>'organization',
        new.raw_user_meta_data->>'org',
        'Káapeh'
      ),
      COALESCE(
        new.raw_user_meta_data->>'role',
        'farmer'
      ),
      COALESCE(
        new.raw_user_meta_data->>'locale',
        'es'
      )
    )
    ON CONFLICT (id) DO UPDATE
    SET 
      name = COALESCE(EXCLUDED.name, profiles.name),
      email = COALESCE(NULLIF(EXCLUDED.email, ''), profiles.email),
      phone = COALESCE(NULLIF(EXCLUDED.phone, ''), profiles.phone),
      organization = COALESCE(NULLIF(EXCLUDED.organization, ''), profiles.organization),
      locale = COALESCE(EXCLUDED.locale, profiles.locale)
    WHERE 
      profiles.name IS NULL OR profiles.name = '' OR
      profiles.phone IS NULL OR profiles.phone = '' OR
      profiles.email IS NULL OR profiles.email = '';
    
    RETURN new;
  END;
END;
$$;

-- Recreate trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW 
  EXECUTE FUNCTION public.handle_new_user();

-- Also create a function to fix existing profiles with missing data
CREATE OR REPLACE FUNCTION public.fix_profile_data(user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_record RECORD;
  extracted_phone TEXT;
BEGIN
  -- Get the auth.users record
  SELECT * INTO user_record 
  FROM auth.users 
  WHERE id = user_id;
  
  IF user_record IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;
  
  -- Extract phone from email if needed
  extracted_phone := CASE 
    WHEN user_record.email LIKE '%@kafe.local' THEN 
      SPLIT_PART(user_record.email, '@', 1)
    ELSE 
      NULL
  END;
  
  -- Update profile with any missing data
  UPDATE public.profiles
  SET
    name = COALESCE(
      NULLIF(name, ''),
      user_record.raw_user_meta_data->>'name',
      user_record.raw_user_meta_data->>'full_name'
    ),
    phone = COALESCE(
      NULLIF(phone, ''),
      user_record.raw_user_meta_data->>'phone',
      extracted_phone
    ),
    email = COALESCE(
      NULLIF(email, ''),
      NULLIF(user_record.raw_user_meta_data->>'email', ''),
      user_record.email
    ),
    organization = COALESCE(
      NULLIF(organization, ''),
      user_record.raw_user_meta_data->>'organization',
      'Káapeh'
    )
  WHERE id = user_id;
END;
$$;

-- Create a function to fix all existing profiles
CREATE OR REPLACE FUNCTION public.fix_all_profiles()
RETURNS TABLE(user_id UUID, status TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as user_id,
    CASE 
      WHEN p.name IS NULL OR p.name = '' OR p.phone IS NULL OR p.phone = '' THEN
        (SELECT public.fix_profile_data(p.id)) || 'Fixed'
      ELSE
        'OK'
    END as status
  FROM public.profiles p;
END;
$$;

COMMIT;

-- Run this to fix any existing profiles with missing data
-- SELECT * FROM public.fix_all_profiles();

-- Verify profiles have data
SELECT 
  id,
  name,
  phone,
  email,
  organization,
  role,
  created_at
FROM public.profiles
ORDER BY created_at DESC
LIMIT 10;
