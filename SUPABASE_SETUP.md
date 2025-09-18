# Supabase Setup Instructions

## 1. Create a Supabase Project
1. Go to https://supabase.com and create a free account
2. Create a new project
3. Wait for the project to be fully set up

## 2. Get Your Project Credentials
1. Go to Settings > API in your Supabase dashboard
2. Copy your Project URL and anon/public API key

## 3. Configure Your Flutter App
1. Open `lib/src/config/supabase_config.dart`
2. Replace `YOUR_SUPABASE_URL` with your actual Project URL
3. Replace `YOUR_SUPABASE_ANON_KEY` with your actual anon/public API key

## 4. Set Up Database Tables
Create the following tables in your Supabase database (SQL Editor):

```sql
-- Users table (extends Supabase auth.users)
CREATE TABLE patients (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Readings table
CREATE TABLE readings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  systolic INTEGER,
  diastolic INTEGER,
  heart_rate INTEGER,
  blood_sugar DECIMAL,
  weight DECIMAL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Appointments table
CREATE TABLE appointments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  description TEXT,
  scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT DEFAULT 'scheduled',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Medications table
CREATE TABLE medications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  dosage TEXT,
  frequency TEXT,
  instructions TEXT,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Alerts table
CREATE TABLE alerts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  message TEXT,
  type TEXT DEFAULT 'info',
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Quizzes table
CREATE TABLE quizzes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  questions JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Questionnaires table
CREATE TABLE questionnaires (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  questions JSONB,
  answers JSONB,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Education content table
CREATE TABLE education_content (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT,
  category TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Support groups table
CREATE TABLE support_groups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Analytics table
CREATE TABLE analytics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  event_type TEXT NOT NULL,
  data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 5. Enable Row Level Security (RLS)
Run these commands to enable RLS and create policies:

```sql
-- Enable RLS on all tables
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE questionnaires ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics ENABLE ROW LEVEL SECURITY;

-- Create policies for users to access only their own data
CREATE POLICY "Users can view own patient record" ON patients FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own patient record" ON patients FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own readings" ON readings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own readings" ON readings FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own appointments" ON appointments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own appointments" ON appointments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own medications" ON medications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own medications" ON medications FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own alerts" ON alerts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own alerts" ON alerts FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own questionnaires" ON questionnaires FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own questionnaires" ON questionnaires FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own analytics" ON analytics FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own analytics" ON analytics FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Public read access for quizzes, education content, and support groups
CREATE POLICY "Anyone can view quizzes" ON quizzes FOR SELECT TO authenticated USING (true);
CREATE POLICY "Anyone can view education content" ON education_content FOR SELECT TO authenticated USING (true);
CREATE POLICY "Anyone can view support groups" ON support_groups FOR SELECT TO authenticated USING (true);
```

## 6. Test Your App
1. Run your Flutter app: `flutter run`
2. Try registering a new user
3. Try logging in with the registered user
4. Check that the user history card loads (even if empty initially)

## Notes
- The app now uses Supabase for authentication, database, and will support file storage
- All Django backend code has been removed
- User authentication is handled by Supabase Auth
- Database queries use Supabase's PostgreSQL database
- Row Level Security ensures users can only access their own data