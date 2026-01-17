-- ============================================
-- Note App Database Schema for Supabase
-- ============================================

-- 1. Profiles Table (extends auth.users)
DROP TABLE IF EXISTS profiles CASCADE;
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies for profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Trigger to auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'username', NEW.email));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 2. Notes Table
-- ============================================
DROP TABLE IF EXISTS notes CASCADE;
CREATE TABLE notes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT DEFAULT '',
  content_json TEXT DEFAULT '[]',
  plain_text TEXT DEFAULT '',
  color_tag TEXT DEFAULT 'none' CHECK (color_tag IN ('none', 'red', 'orange', 'yellow', 'green', 'blue', 'purple', 'pink')),
  is_pinned BOOLEAN DEFAULT FALSE,
  is_private BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_created_at ON notes(created_at DESC);
CREATE INDEX idx_notes_is_pinned ON notes(is_pinned);
CREATE INDEX idx_notes_color_tag ON notes(color_tag);
CREATE INDEX idx_notes_is_private ON notes(is_private);
CREATE INDEX idx_notes_plain_text ON notes USING gin(to_tsvector('english', plain_text));

-- Enable Row Level Security
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Policies for notes
DROP POLICY IF EXISTS "Users can view own notes" ON notes;
CREATE POLICY "Users can view own notes"
  ON notes FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own notes" ON notes;
CREATE POLICY "Users can insert own notes"
  ON notes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notes" ON notes;
CREATE POLICY "Users can update own notes"
  ON notes FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own notes" ON notes;
CREATE POLICY "Users can delete own notes"
  ON notes FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_notes_updated_at ON notes;
CREATE TRIGGER update_notes_updated_at
  BEFORE UPDATE ON notes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 3. Safe Passwords Table (for Private Notes)
-- ============================================
DROP TABLE IF EXISTS safe_passwords CASCADE;
CREATE TABLE safe_passwords (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE PRIMARY KEY,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE safe_passwords ENABLE ROW LEVEL SECURITY;

-- Policies for safe_passwords
DROP POLICY IF EXISTS "Users can manage own safe password" ON safe_passwords;
CREATE POLICY "Users can manage own safe password"
  ON safe_passwords FOR ALL
  USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS update_safe_passwords_updated_at ON safe_passwords;
CREATE TRIGGER update_safe_passwords_updated_at
  BEFORE UPDATE ON safe_passwords
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 4. Helper Functions
-- ============================================

-- Function to search notes
CREATE OR REPLACE FUNCTION search_notes(
  search_query TEXT,
  user_id_param UUID
)
RETURNS SETOF notes AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM notes
  WHERE user_id = user_id_param
    AND is_private = FALSE
    AND (
      title ILIKE '%' || search_query || '%'
      OR plain_text ILIKE '%' || search_query || '%'
    )
  ORDER BY is_pinned DESC, updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get notes by color tag
CREATE OR REPLACE FUNCTION get_notes_by_color(
  color_tag_param TEXT,
  user_id_param UUID
)
RETURNS SETOF notes AS $$
BEGIN
  IF color_tag_param = 'none' THEN
    RETURN QUERY
    SELECT * FROM notes
    WHERE user_id = user_id_param
      AND is_private = FALSE
    ORDER BY is_pinned DESC, updated_at DESC;
  ELSE
    RETURN QUERY
    SELECT * FROM notes
    WHERE user_id = user_id_param
      AND is_private = FALSE
      AND color_tag = color_tag_param
    ORDER BY is_pinned DESC, updated_at DESC;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get private notes
CREATE OR REPLACE FUNCTION get_private_notes(
  user_id_param UUID
)
RETURNS SETOF notes AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM notes
  WHERE user_id = user_id_param
    AND is_private = TRUE
  ORDER BY is_pinned DESC, updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 5. Sample Data (Optional - Remove in production)
-- ============================================
-- You can insert sample data here for testing
