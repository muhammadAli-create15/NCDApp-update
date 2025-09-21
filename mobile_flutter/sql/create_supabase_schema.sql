-- Supabase / Postgres schema for NCDApp (generated from code analysis)
-- Run these statements in your Supabase SQL editor (Dashboard > SQL Editor)

-- 1) Profiles (connected to auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  first_name text,
  last_name text,
  full_name text,
  avatar_url text,
  phone text,
  bio text,
  metadata jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 2) Patients (lightweight patient registry)
CREATE TABLE IF NOT EXISTS public.patients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  name text NOT NULL,
  dob date,
  gender text,
  contact jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 3) Readings (medical readings)
CREATE TABLE IF NOT EXISTS public.readings (
  id BIGSERIAL PRIMARY KEY,
  patient_id uuid REFERENCES public.patients(id) ON DELETE SET NULL,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  name text,
  age text,
  blood_pressure text,
  heart_rate text,
  respiratory_rate text,
  temperature text,
  height text,
  weight text,
  bmi text,
  fasting_blood_glucose text,
  random_blood_glucose text,
  hba1c text,
  lipid_profile text,
  serum_creatinine text,
  blood_urea_nitrogen text,
  egfr text,
  electrolytes text,
  liver_function_tests text,
  echocardiography text,
  entered_by text,
  created_at timestamptz DEFAULT now()
);

-- 4) Appointments
CREATE TABLE IF NOT EXISTS public.appointments (
  id BIGSERIAL PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  date timestamptz NOT NULL,
  location text,
  doctor_name text,
  status varchar(32) DEFAULT 'scheduled',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 5) Medications
CREATE TABLE IF NOT EXISTS public.medications (
  id BIGSERIAL PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  dosage text,
  frequency text,
  start_date date,
  end_date date,
  notes text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- 6) Alerts / Notifications
CREATE TABLE IF NOT EXISTS public.alerts (
  id BIGSERIAL PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  alert_type varchar(50) DEFAULT 'info',
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- 7) Support groups
CREATE TABLE IF NOT EXISTS public.support_groups (
  group_id text PRIMARY KEY,
  name text NOT NULL,
  description text,
  icon_url text,
  moderator_ids uuid[] DEFAULT '{}',
  guidelines text,
  is_active boolean DEFAULT true,
  last_updated timestamptz DEFAULT now()
);

-- 8) Discussion posts (support groups)
CREATE TABLE IF NOT EXISTS public.discussion_posts (
  post_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id text REFERENCES public.support_groups(group_id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  user_display_name text,
  title text NOT NULL,
  content text,
  is_pinned boolean DEFAULT false,
  is_edited boolean DEFAULT false,
  likes uuid[] DEFAULT '{}',
  comment_count int DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 9) Post comments
CREATE TABLE IF NOT EXISTS public.post_comments (
  comment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid REFERENCES public.discussion_posts(post_id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  user_display_name text,
  content text,
  is_edited boolean DEFAULT false,
  likes uuid[] DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

-- 10) Chats and messages
CREATE TABLE IF NOT EXISTS public.chats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_ids uuid[] NOT NULL,
  is_group boolean DEFAULT false,
  meta jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id uuid REFERENCES public.chats(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  receiver_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  content text,
  type varchar(32) DEFAULT 'text',
  status varchar(32) DEFAULT 'sent',
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- 11) Storage metadata (optional) for attachments referenced in DB
CREATE TABLE IF NOT EXISTS public.attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bucket_name text NOT NULL,
  path text NOT NULL,
  url text,
  uploaded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  content_type text,
  size bigint,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- 12) Quizzes and attempts
CREATE TABLE IF NOT EXISTS public.quizzes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  category text,
  difficulty text,
  time_limit int,
  questions jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.quiz_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id uuid REFERENCES public.quizzes(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  start_time timestamptz DEFAULT now(),
  end_time timestamptz,
  score numeric,
  answers jsonb,
  completed boolean DEFAULT false
);

-- 13) Questionnaires (basic schema)
CREATE TABLE IF NOT EXISTS public.questionnaires (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text,
  description text,
  schema jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.questionnaire_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  questionnaire_id uuid REFERENCES public.questionnaires(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  responses jsonb,
  created_at timestamptz DEFAULT now()
);

-- 14) Educational content
CREATE TABLE IF NOT EXISTS public.education_content (
  content_id text PRIMARY KEY,
  title text,
  body text,
  category text,
  target_risk_factor text,
  target_risk_levels text[],
  priority int DEFAULT 0,
  last_updated timestamptz DEFAULT now(),
  references text[],
  actionable_steps text[],
  is_saved boolean DEFAULT false,
  is_read boolean DEFAULT false
);

-- 15) Analytics events
CREATE TABLE IF NOT EXISTS public.analytics (
  id BIGSERIAL PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  event_type text,
  properties jsonb,
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security for user-owned tables and create basic policies
-- Tables that should restrict access to the owning user:
DO $$
BEGIN
  -- readings
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='readings') THEN
    -- table not found skip
    NULL;
  END IF;
END$$;

-- Enable RLS and policies for tables that store per-user data
ALTER TABLE IF EXISTS public.readings ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS readings_select ON public.readings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS readings_insert ON public.readings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS readings_update ON public.readings FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS readings_delete ON public.readings FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE IF EXISTS public.appointments ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS appointments_manage ON public.appointments FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE IF EXISTS public.medications ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS medications_manage ON public.medications FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE IF EXISTS public.alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT_EXISTS alerts_manage ON public.alerts FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE IF EXISTS public.quiz_attempts ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS quiz_attempts_manage ON public.quiz_attempts FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE IF EXISTS public.questionnaire_responses ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS questionnaire_responses_manage ON public.questionnaire_responses FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE IF EXISTS public.analytics ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS analytics_insert ON public.analytics FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY IF NOT_EXISTS analytics_select ON public.analytics FOR SELECT USING (auth.uid() = user_id);

-- For chat messages, allow participants to read messages in chats they are part of
ALTER TABLE IF EXISTS public.chats ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS chats_participant_access ON public.chats FOR SELECT USING (auth.uid() = ANY (participant_ids));
CREATE POLICY IF NOT EXISTS chats_insert ON public.chats FOR INSERT WITH CHECK (auth.uid() = ANY (participant_ids));

ALTER TABLE IF EXISTS public.chat_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS chat_messages_select ON public.chat_messages FOR SELECT USING (
  auth.uid() = sender_id OR auth.uid() = receiver_id OR auth.uid() IN (SELECT unnest((SELECT participant_ids FROM public.chats WHERE id = chat_id)))
);
CREATE POLICY IF NOT EXISTS chat_messages_insert ON public.chat_messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Public tables (readable by public) — support groups, posts, educational content
ALTER TABLE IF EXISTS public.support_groups ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS_support_groups_public_select ON public.support_groups FOR SELECT USING (true);

ALTER TABLE IF EXISTS public.discussion_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT_EXISTS_discussion_posts_public_select ON public.discussion_posts FOR SELECT USING (true);

ALTER TABLE IF EXISTS public.post_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT_EXISTS_post_comments_public_select ON public.post_comments FOR SELECT USING (true);

ALTER TABLE IF EXISTS public.education_content ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT_EXISTS_education_content_public_select ON public.education_content FOR SELECT USING (true);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_readings_user_created_at ON public.readings (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_appointments_user_date ON public.appointments (user_id, date);
CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_created ON public.chat_messages (chat_id, created_at DESC);

-- End of schema
