-- ============================================
-- Migration: Add email column to profiles table
-- Date: 2026-01-17
-- ============================================

-- Add email column to profiles table (if not exists)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'email'
  ) THEN
    ALTER TABLE profiles ADD COLUMN email TEXT;
    
    -- Set NOT NULL constraint after populating data
    -- First, populate email from auth.users
    UPDATE profiles p
    SET email = u.email
    FROM auth.users u
    WHERE p.id = u.id;
    
    -- Now make it NOT NULL
    ALTER TABLE profiles ALTER COLUMN email SET NOT NULL;
    
    -- Add UNIQUE constraint
    ALTER TABLE profiles ADD CONSTRAINT profiles_email_key UNIQUE (email);
    
    RAISE NOTICE 'Email column added to profiles table';
  ELSE
    RAISE NOTICE 'Email column already exists';
  END IF;
  
  RAISE NOTICE 'Migration completed successfully';
END $$;

-- Update the trigger function to include email
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'username', NEW.email))
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email,
      username = EXCLUDED.username,
      updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
