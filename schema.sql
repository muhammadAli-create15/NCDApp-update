-- NCD App Supabase Schema
-- Created: September 19, 2025

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- USER AUTHENTICATION TABLES
-- =============================================================================

-- NOTE: auth.users is managed by Supabase Auth, we'll create additional tables
-- to extend the functionality

-- User profiles table - extends the auth.users table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    avatar_url TEXT,
    bio TEXT,
    is_online BOOLEAN DEFAULT false,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- User types/roles table
CREATE TABLE public.user_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Link users to their roles
CREATE TABLE public.user_roles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type_id INTEGER NOT NULL REFERENCES public.user_types(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    UNIQUE(user_id, type_id)
);

-- User settings table
CREATE TABLE public.user_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    notification_enabled BOOLEAN DEFAULT true,
    theme VARCHAR(20) DEFAULT 'light',
    language VARCHAR(10) DEFAULT 'en',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Insert default user types
INSERT INTO public.user_types (name, description) VALUES
('patient', 'Regular patient user'),
('healthcare_provider', 'Medical professionals providing healthcare services'),
('admin', 'System administrator');

-- User locations/addresses
CREATE TABLE public.user_addresses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL,
    is_default BOOLEAN DEFAULT false,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Medical professionals specific table
CREATE TABLE public.healthcare_providers (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    specialty VARCHAR(100) NOT NULL,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    years_of_experience INTEGER,
    hospital_affiliation VARCHAR(255),
    available_for_consultation BOOLEAN DEFAULT false,
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- User verification table (for email and phone verification)
CREATE TABLE public.user_verifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    email_verification_token UUID,
    phone_verification_code VARCHAR(6),
    token_expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- User connections/relationships table (for friends/contacts)
CREATE TABLE public.user_connections (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    connected_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
    initiated_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    UNIQUE(user_id, connected_user_id)
);

-- Create trigger function to update timestamps
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for all tables with updated_at
CREATE TRIGGER update_profiles_timestamp BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_user_roles_timestamp BEFORE UPDATE ON public.user_roles
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_user_settings_timestamp BEFORE UPDATE ON public.user_settings
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_user_types_timestamp BEFORE UPDATE ON public.user_types
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_user_addresses_timestamp BEFORE UPDATE ON public.user_addresses
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_healthcare_providers_timestamp BEFORE UPDATE ON public.healthcare_providers
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_user_verifications_timestamp BEFORE UPDATE ON public.user_verifications
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_user_connections_timestamp BEFORE UPDATE ON public.user_connections
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- Create or update profile on user creation
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, first_name, last_name, avatar_url)
  VALUES (NEW.id, '', '', '');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger the function on new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- HEALTH RECORD TABLES
-- =============================================================================

-- Patient medical records table
CREATE TABLE public.patient_records (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    blood_type VARCHAR(5) CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    allergies TEXT[],
    height_cm DECIMAL(5,2),
    weight_kg DECIMAL(5,2),
    medical_conditions TEXT[],
    medications TEXT[],
    family_history TEXT,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Vital signs tracking
CREATE TABLE public.vital_signs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    recorded_by UUID REFERENCES public.profiles(id),
    temperature DECIMAL(4,1),
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    heart_rate INTEGER,
    respiratory_rate INTEGER,
    oxygen_saturation DECIMAL(4,1),
    blood_glucose DECIMAL(5,1),
    measured_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- NCD risk assessment table
CREATE TABLE public.ncd_risk_assessments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    assessor_id UUID REFERENCES public.profiles(id),
    smoking_status VARCHAR(20) CHECK (smoking_status IN ('never', 'former', 'current', 'unknown')),
    physical_activity_level INTEGER CHECK (physical_activity_level BETWEEN 0 AND 10),
    alcohol_consumption VARCHAR(20) CHECK (alcohol_consumption IN ('none', 'light', 'moderate', 'heavy', 'unknown')),
    diet_quality INTEGER CHECK (diet_quality BETWEEN 0 AND 10),
    stress_level INTEGER CHECK (stress_level BETWEEN 0 AND 10),
    sleep_hours DECIMAL(3,1),
    bmi DECIMAL(4,1),
    waist_circumference DECIMAL(5,1),
    diabetes_risk_score INTEGER,
    hypertension_risk_score INTEGER,
    cardiovascular_risk_score INTEGER,
    stroke_risk_score INTEGER,
    respiratory_risk_score INTEGER,
    assessment_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- NCD diagnoses table
CREATE TABLE public.ncd_diagnoses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    diagnosed_by UUID REFERENCES public.profiles(id),
    condition_type VARCHAR(50) NOT NULL CHECK (condition_type IN (
        'hypertension', 'diabetes', 'cardiovascular_disease', 'stroke',
        'cancer', 'respiratory_disease', 'mental_health'
    )),
    diagnosis_details TEXT,
    severity VARCHAR(20) CHECK (severity IN ('mild', 'moderate', 'severe', 'unknown')),
    diagnosis_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Treatment plans table
CREATE TABLE public.treatment_plans (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    diagnosis_id UUID REFERENCES public.ncd_diagnoses(id),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(20) CHECK (status IN ('active', 'completed', 'cancelled', 'on_hold')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Medication prescriptions table
CREATE TABLE public.medication_prescriptions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    treatment_plan_id UUID REFERENCES public.treatment_plans(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    prescribed_by UUID NOT NULL REFERENCES public.profiles(id),
    medication_name VARCHAR(255) NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    instructions TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Health goals table
CREATE TABLE public.health_goals (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    target_date DATE,
    status VARCHAR(20) CHECK (status IN ('not_started', 'in_progress', 'achieved', 'abandoned')),
    progress INTEGER CHECK (progress BETWEEN 0 AND 100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Health appointments table
CREATE TABLE public.appointments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES public.profiles(id),
    provider_id UUID NOT NULL REFERENCES public.healthcare_providers(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    duration_minutes INTEGER NOT NULL,
    status VARCHAR(20) CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no_show', 'rescheduled')),
    location VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Health data tracking - for custom tracking metrics
CREATE TABLE public.health_metrics (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    unit VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Health tracking entries
CREATE TABLE public.health_tracking_entries (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    metric_id INTEGER NOT NULL REFERENCES public.health_metrics(id),
    value DECIMAL(10,2) NOT NULL,
    entry_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Initial health metrics
INSERT INTO public.health_metrics (name, description, unit) VALUES
('Blood Glucose', 'Blood sugar level', 'mg/dL'),
('Weight', 'Body weight', 'kg'),
('Blood Pressure', 'Blood pressure measurement', 'mmHg'),
('Steps', 'Number of steps taken', 'count'),
('Sleep Duration', 'Hours of sleep', 'hours'),
('Water Intake', 'Amount of water consumed', 'ml');

-- Add triggers for all health record tables
CREATE TRIGGER update_patient_records_timestamp BEFORE UPDATE ON public.patient_records
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_vital_signs_timestamp BEFORE UPDATE ON public.vital_signs
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_ncd_risk_assessments_timestamp BEFORE UPDATE ON public.ncd_risk_assessments
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_ncd_diagnoses_timestamp BEFORE UPDATE ON public.ncd_diagnoses
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_treatment_plans_timestamp BEFORE UPDATE ON public.treatment_plans
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_medication_prescriptions_timestamp BEFORE UPDATE ON public.medication_prescriptions
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_health_goals_timestamp BEFORE UPDATE ON public.health_goals
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_appointments_timestamp BEFORE UPDATE ON public.appointments
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_health_metrics_timestamp BEFORE UPDATE ON public.health_metrics
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_health_tracking_entries_timestamp BEFORE UPDATE ON public.health_tracking_entries
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- =============================================================================
-- MESSAGING SYSTEM TABLES
-- =============================================================================

-- Chat types enum
CREATE TYPE chat_type AS ENUM ('direct', 'group', 'channel');

-- Message types enum
CREATE TYPE message_type AS ENUM ('text', 'image', 'video', 'audio', 'file', 'location');

-- Message status enum
CREATE TYPE message_status AS ENUM ('sent', 'delivered', 'read', 'failed');

-- Chats/conversations table
CREATE TABLE public.chats (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    type chat_type NOT NULL DEFAULT 'direct',
    name VARCHAR(255),
    description TEXT,
    created_by UUID NOT NULL REFERENCES public.profiles(id),
    is_active BOOLEAN DEFAULT true,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Chat participants
CREATE TABLE public.chat_participants (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    is_muted BOOLEAN DEFAULT false,
    left_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    UNIQUE(chat_id, user_id)
);

-- Messages table
CREATE TABLE public.messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id),
    parent_id UUID REFERENCES public.messages(id),
    type message_type NOT NULL DEFAULT 'text',
    content TEXT NOT NULL,
    metadata JSONB,
    is_edited BOOLEAN DEFAULT false,
    edited_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Message status tracking
CREATE TABLE public.message_status_tracking (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status message_status NOT NULL DEFAULT 'sent',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    UNIQUE(message_id, user_id)
);

-- Offline pending messages queue
CREATE TABLE public.offline_messages_queue (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    message_type message_type NOT NULL DEFAULT 'text',
    content TEXT NOT NULL,
    metadata JSONB,
    parent_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    retry_count INTEGER DEFAULT 0,
    last_retry_at TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(20) DEFAULT 'pending' CHECK (sync_status IN ('pending', 'syncing', 'failed'))
);

-- Typing status tracking (could be implemented with Supabase Realtime or this table)
CREATE TABLE public.typing_status (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT false,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    UNIQUE(chat_id, user_id)
);

-- Add triggers for all messaging tables
CREATE TRIGGER update_chats_timestamp BEFORE UPDATE ON public.chats
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_chat_participants_timestamp BEFORE UPDATE ON public.chat_participants
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_messages_timestamp BEFORE UPDATE ON public.messages
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_message_status_tracking_timestamp BEFORE UPDATE ON public.message_status_tracking
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_typing_status_timestamp BEFORE UPDATE ON public.typing_status
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- Update last message timestamp in chats when a new message is added
CREATE OR REPLACE FUNCTION update_chat_last_message_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   UPDATE public.chats
   SET last_message_at = NEW.created_at
   WHERE id = NEW.chat_id;
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_chat_last_message_timestamp
AFTER INSERT ON public.messages
FOR EACH ROW EXECUTE FUNCTION update_chat_last_message_timestamp();

-- Add initial message status entries for all participants when a message is sent
CREATE OR REPLACE FUNCTION add_message_status_for_participants()
RETURNS TRIGGER AS $$
DECLARE
    participant RECORD;
BEGIN
    FOR participant IN (
        SELECT user_id 
        FROM public.chat_participants 
        WHERE chat_id = NEW.chat_id AND user_id != NEW.sender_id
    ) LOOP
        INSERT INTO public.message_status_tracking (message_id, user_id, status)
        VALUES (NEW.id, participant.user_id, 'sent');
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_add_message_status_for_participants
AFTER INSERT ON public.messages
FOR EACH ROW EXECUTE FUNCTION add_message_status_for_participants();

-- =============================================================================
-- ATTACHMENT HANDLING TABLES
-- =============================================================================

-- File mime types table for common file types
CREATE TABLE public.file_mime_types (
    id SERIAL PRIMARY KEY,
    mime_type VARCHAR(100) NOT NULL UNIQUE,
    extension VARCHAR(20),
    category VARCHAR(50) CHECK (category IN ('image', 'video', 'audio', 'document', 'other')),
    icon VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Message attachments table
CREATE TABLE public.message_attachments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100) REFERENCES public.file_mime_types(mime_type),
    storage_path TEXT NOT NULL,
    storage_bucket VARCHAR(100) NOT NULL,
    public_url TEXT,
    width INTEGER, -- for images and videos
    height INTEGER, -- for images and videos
    duration INTEGER, -- for audio and video (in seconds)
    thumbnail_url TEXT, -- for videos and images
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Post attachments table (for community posts/health tips)
CREATE TABLE public.post_attachments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    post_id UUID NOT NULL, -- Will reference public.posts once created
    file_name VARCHAR(255) NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100) REFERENCES public.file_mime_types(mime_type),
    storage_path TEXT NOT NULL,
    storage_bucket VARCHAR(100) NOT NULL,
    public_url TEXT,
    width INTEGER, -- for images and videos
    height INTEGER, -- for images and videos
    duration INTEGER, -- for audio and video (in seconds)
    thumbnail_url TEXT, -- for videos and images
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- User avatar attachments (specific table for profile pictures)
CREATE TABLE public.user_avatars (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    storage_path TEXT NOT NULL,
    storage_bucket VARCHAR(100) NOT NULL,
    public_url TEXT NOT NULL,
    width INTEGER,
    height INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Medical records attachments (for secure medical documents)
CREATE TABLE public.medical_record_attachments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    record_id UUID NOT NULL, -- Can reference different medical record tables
    record_type VARCHAR(50) NOT NULL, -- Type of record this is attached to
    file_name VARCHAR(255) NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100) REFERENCES public.file_mime_types(mime_type),
    storage_path TEXT NOT NULL,
    storage_bucket VARCHAR(100) NOT NULL,
    is_public BOOLEAN DEFAULT false,
    public_url TEXT, -- Only populated if is_public is true
    uploaded_by UUID NOT NULL REFERENCES public.profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Attachment downloads tracking
CREATE TABLE public.attachment_downloads (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    attachment_type VARCHAR(50) NOT NULL, -- message_attachments, post_attachments, etc.
    attachment_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    downloaded_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    client_ip VARCHAR(50),
    user_agent TEXT
);

-- Insert common MIME types
INSERT INTO public.file_mime_types (mime_type, extension, category, icon) VALUES
('image/jpeg', 'jpg', 'image', 'image'),
('image/png', 'png', 'image', 'image'),
('image/gif', 'gif', 'image', 'gif'),
('image/webp', 'webp', 'image', 'image'),
('video/mp4', 'mp4', 'video', 'video'),
('video/quicktime', 'mov', 'video', 'video'),
('video/webm', 'webm', 'video', 'video'),
('audio/mpeg', 'mp3', 'audio', 'audio'),
('audio/wav', 'wav', 'audio', 'audio'),
('audio/ogg', 'ogg', 'audio', 'audio'),
('application/pdf', 'pdf', 'document', 'pdf'),
('application/msword', 'doc', 'document', 'doc'),
('application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'docx', 'document', 'doc'),
('application/vnd.ms-excel', 'xls', 'document', 'excel'),
('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'xlsx', 'document', 'excel'),
('text/plain', 'txt', 'document', 'text'),
('application/zip', 'zip', 'other', 'zip'),
('application/json', 'json', 'other', 'code');

-- Add triggers for attachment tables
CREATE TRIGGER update_file_mime_types_timestamp BEFORE UPDATE ON public.file_mime_types
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_message_attachments_timestamp BEFORE UPDATE ON public.message_attachments
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_post_attachments_timestamp BEFORE UPDATE ON public.post_attachments
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_user_avatars_timestamp BEFORE UPDATE ON public.user_avatars
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_medical_record_attachments_timestamp BEFORE UPDATE ON public.medical_record_attachments
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- =============================================================================
-- CONTENT MANAGEMENT TABLES
-- =============================================================================

-- Categories table for health content
CREATE TABLE public.content_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon VARCHAR(100),
    parent_id INTEGER REFERENCES public.content_categories(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Tags for content categorization
CREATE TABLE public.content_tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Health articles and educational content
CREATE TABLE public.articles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    author_id UUID REFERENCES public.profiles(id),
    category_id INTEGER REFERENCES public.content_categories(id),
    summary TEXT,
    content TEXT NOT NULL,
    featured_image_url TEXT,
    view_count INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT false,
    published_at TIMESTAMP WITH TIME ZONE,
    is_featured BOOLEAN DEFAULT false,
    reading_time_minutes INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Link articles to tags (many-to-many)
CREATE TABLE public.article_tags (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    article_id UUID NOT NULL REFERENCES public.articles(id) ON DELETE CASCADE,
    tag_id INTEGER NOT NULL REFERENCES public.content_tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    UNIQUE(article_id, tag_id)
);

-- Health tips table (shorter content)
CREATE TABLE public.health_tips (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    author_id UUID REFERENCES public.profiles(id),
    category_id INTEGER REFERENCES public.content_categories(id),
    featured_image_url TEXT,
    is_published BOOLEAN DEFAULT true,
    published_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- User-generated community posts
CREATE TABLE public.community_posts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    category_id INTEGER REFERENCES public.content_categories(id),
    visibility VARCHAR(20) CHECK (visibility IN ('public', 'connections', 'private')) DEFAULT 'public',
    is_anonymous BOOLEAN DEFAULT false,
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Comments on articles and community posts
CREATE TABLE public.comments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('article', 'health_tip', 'community_post')),
    content_id UUID NOT NULL,
    parent_id UUID REFERENCES public.comments(id),
    content TEXT NOT NULL,
    is_approved BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Likes/reactions for content
CREATE TABLE public.content_reactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('article', 'health_tip', 'community_post', 'comment')),
    content_id UUID NOT NULL,
    reaction_type VARCHAR(20) NOT NULL CHECK (reaction_type IN ('like', 'love', 'support', 'insightful', 'thanks')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    UNIQUE(user_id, content_type, content_id)
);

-- FAQ categories
CREATE TABLE public.faq_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- FAQs table
CREATE TABLE public.faqs (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES public.faq_categories(id),
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    is_published BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Notifications table
CREATE TABLE public.notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    action_url TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- User notification preferences
CREATE TABLE public.notification_preferences (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    email_enabled BOOLEAN DEFAULT true,
    push_enabled BOOLEAN DEFAULT true,
    in_app_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    UNIQUE(user_id, notification_type)
);

-- Insert some initial content categories
INSERT INTO public.content_categories (name, slug, description, icon) VALUES
('Diabetes', 'diabetes', 'Information related to diabetes prevention and management', 'diabetes'),
('Hypertension', 'hypertension', 'Information related to hypertension prevention and management', 'heart'),
('Cardiovascular Health', 'cardiovascular-health', 'Information related to heart health', 'cardiovascular'),
('Mental Health', 'mental-health', 'Information related to mental health and wellness', 'mental_health'),
('Nutrition', 'nutrition', 'Information about healthy eating and nutrition', 'nutrition'),
('Exercise', 'exercise', 'Physical activity and fitness information', 'fitness'),
('Lifestyle', 'lifestyle', 'General lifestyle modifications for health', 'lifestyle'),
('Medication', 'medication', 'Information about medication management', 'medication');

-- Insert some initial FAQ categories
INSERT INTO public.faq_categories (name, description, icon) VALUES
('General', 'General questions about the app and services', 'question_mark'),
('Account', 'Questions about account setup and management', 'account'),
('Health Records', 'Questions about managing health records', 'health'),
('Messaging', 'Questions about the messaging features', 'message'),
('Privacy', 'Questions about privacy and data protection', 'privacy');

-- Add triggers for content management tables
CREATE TRIGGER update_content_categories_timestamp BEFORE UPDATE ON public.content_categories
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_content_tags_timestamp BEFORE UPDATE ON public.content_tags
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_articles_timestamp BEFORE UPDATE ON public.articles
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_health_tips_timestamp BEFORE UPDATE ON public.health_tips
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_community_posts_timestamp BEFORE UPDATE ON public.community_posts
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_comments_timestamp BEFORE UPDATE ON public.comments
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_faq_categories_timestamp BEFORE UPDATE ON public.faq_categories
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_faqs_timestamp BEFORE UPDATE ON public.faqs
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_notifications_timestamp BEFORE UPDATE ON public.notifications
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_notification_preferences_timestamp BEFORE UPDATE ON public.notification_preferences
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- =============================================================================
-- ROW LEVEL SECURITY POLICIES
-- =============================================================================

-- Enable Row Level Security for all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.healthcare_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vital_signs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ncd_risk_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ncd_diagnoses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treatment_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_tracking_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_status_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offline_messages_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.typing_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.file_mime_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_avatars ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_record_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attachment_downloads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.article_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_tips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faq_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.user_types ut ON ur.type_id = ut.id
    WHERE ur.user_id = auth.uid() AND ut.name = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user is a healthcare provider
CREATE OR REPLACE FUNCTION public.is_healthcare_provider()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.user_types ut ON ur.type_id = ut.id
    WHERE ur.user_id = auth.uid() AND ut.name = 'healthcare_provider'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user is in a chat
CREATE OR REPLACE FUNCTION public.is_chat_participant(chat_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.chat_participants
    WHERE chat_id = chat_uuid AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- PROFILE POLICIES
-- ==========================================

-- Anyone can read profiles (limited information)
CREATE POLICY "Profiles are viewable by everyone"
ON public.profiles FOR SELECT
TO authenticated
USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (id = auth.uid());

-- ==========================================
-- USER ROLES POLICIES
-- ==========================================

-- Anyone can read user_roles
CREATE POLICY "User roles are viewable by everyone"
ON public.user_roles FOR SELECT
TO authenticated
USING (true);

-- Only admins can insert/update/delete user_roles
CREATE POLICY "Only admins can manage user roles"
ON public.user_roles FOR ALL
TO authenticated
USING (public.is_admin());

-- ==========================================
-- USER SETTINGS POLICIES
-- ==========================================

-- Users can view their own settings
CREATE POLICY "Users can view their own settings"
ON public.user_settings FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can update their own settings
CREATE POLICY "Users can update their own settings"
ON public.user_settings FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

-- Users can insert their own settings
CREATE POLICY "Users can insert their own settings"
ON public.user_settings FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- ==========================================
-- USER CONNECTIONS POLICIES
-- ==========================================

-- Users can view their own connections
CREATE POLICY "Users can view their own connections"
ON public.user_connections FOR SELECT
TO authenticated
USING (user_id = auth.uid() OR connected_user_id = auth.uid());

-- Users can create connection requests
CREATE POLICY "Users can create connection requests"
ON public.user_connections FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid() OR connected_user_id = auth.uid());

-- Users can update their own connection status
CREATE POLICY "Users can update connection status"
ON public.user_connections FOR UPDATE
TO authenticated
USING (user_id = auth.uid() OR connected_user_id = auth.uid());

-- ==========================================
-- PATIENT RECORDS POLICIES
-- ==========================================

-- Patients can view their own records
CREATE POLICY "Patients can view their own records"
ON public.patient_records FOR SELECT
TO authenticated
USING (patient_id = auth.uid());

-- Healthcare providers can view their patients' records
CREATE POLICY "Healthcare providers can view patient records"
ON public.patient_records FOR SELECT
TO authenticated
USING (public.is_healthcare_provider());

-- Patients can update their own basic records
CREATE POLICY "Patients can update their own records"
ON public.patient_records FOR UPDATE
TO authenticated
USING (patient_id = auth.uid());

-- Healthcare providers can update patient records
CREATE POLICY "Healthcare providers can update patient records"
ON public.patient_records FOR UPDATE
TO authenticated
USING (public.is_healthcare_provider());

-- Healthcare providers can insert patient records
CREATE POLICY "Healthcare providers can insert patient records"
ON public.patient_records FOR INSERT
TO authenticated
WITH CHECK (public.is_healthcare_provider());

-- ==========================================
-- VITAL SIGNS POLICIES
-- ==========================================

-- Patients can view their own vital signs
CREATE POLICY "Patients can view their own vital signs"
ON public.vital_signs FOR SELECT
TO authenticated
USING (patient_id = auth.uid());

-- Healthcare providers can view their patients' vital signs
CREATE POLICY "Healthcare providers can view patient vital signs"
ON public.vital_signs FOR SELECT
TO authenticated
USING (public.is_healthcare_provider());

-- Patients can insert their own vital signs
CREATE POLICY "Patients can insert their own vital signs"
ON public.vital_signs FOR INSERT
TO authenticated
WITH CHECK (patient_id = auth.uid());

-- Healthcare providers can insert patient vital signs
CREATE POLICY "Healthcare providers can insert patient vital signs"
ON public.vital_signs FOR INSERT
TO authenticated
WITH CHECK (public.is_healthcare_provider());

-- ==========================================
-- CHAT AND MESSAGING POLICIES
-- ==========================================

-- Users can select chats they participate in
CREATE POLICY "Users can view chats they participate in"
ON public.chats FOR SELECT
TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.chat_participants
  WHERE chat_id = id AND user_id = auth.uid()
));

-- Users can insert chats
CREATE POLICY "Users can create new chats"
ON public.chats FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid());

-- Users can view messages in chats they participate in
CREATE POLICY "Users can view messages in their chats"
ON public.messages FOR SELECT
TO authenticated
USING (public.is_chat_participant(chat_id));

-- Users can insert messages in chats they participate in
CREATE POLICY "Users can send messages to their chats"
ON public.messages FOR INSERT
TO authenticated
WITH CHECK (
  public.is_chat_participant(chat_id) AND
  sender_id = auth.uid()
);

-- Users can update their own messages
CREATE POLICY "Users can update their own messages"
ON public.messages FOR UPDATE
TO authenticated
USING (sender_id = auth.uid());

-- ==========================================
-- MESSAGE ATTACHMENTS POLICIES
-- ==========================================

-- Users can view attachments in their chats
CREATE POLICY "Users can view attachments in their chats"
ON public.message_attachments FOR SELECT
TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.messages m
  JOIN public.chat_participants cp ON m.chat_id = cp.chat_id
  WHERE m.id = message_id AND cp.user_id = auth.uid()
));

-- Users can upload attachments to their messages
CREATE POLICY "Users can upload attachments to their messages"
ON public.message_attachments FOR INSERT
TO authenticated
WITH CHECK (EXISTS (
  SELECT 1 FROM public.messages
  WHERE id = message_id AND sender_id = auth.uid()
));

-- ==========================================
-- NOTIFICATION POLICIES
-- ==========================================

-- Users can view their own notifications
CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can update their own notification read status
CREATE POLICY "Users can update their own notification status"
ON public.notifications FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

-- ==========================================
-- CONTENT POLICIES
-- ==========================================

-- Everyone can view published articles
CREATE POLICY "Everyone can view published articles"
ON public.articles FOR SELECT
TO authenticated
USING (is_published = true OR author_id = auth.uid());

-- Users can view all public community posts
CREATE POLICY "Everyone can view public community posts"
ON public.community_posts FOR SELECT
TO authenticated
USING (
  visibility = 'public' OR 
  author_id = auth.uid() OR
  (visibility = 'connections' AND EXISTS (
    SELECT 1 FROM user_connections WHERE 
    (user_id = auth.uid() AND connected_user_id = author_id) OR
    (connected_user_id = auth.uid() AND user_id = author_id)
  ))
);

-- Users can create their own community posts
CREATE POLICY "Users can create their own community posts"
ON public.community_posts FOR INSERT
TO authenticated
WITH CHECK (author_id = auth.uid());

-- Users can update their own community posts
CREATE POLICY "Users can update their own community posts"
ON public.community_posts FOR UPDATE
TO authenticated
USING (author_id = auth.uid());

-- Users can delete their own community posts
CREATE POLICY "Users can delete their own community posts"
ON public.community_posts FOR DELETE
TO authenticated
USING (author_id = auth.uid());

-- =============================================================================
-- POSTGRESQL FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Function to create notification for message
CREATE OR REPLACE FUNCTION public.handle_new_message() 
RETURNS TRIGGER AS $$
DECLARE
  chat_participant RECORD;
BEGIN
  -- Skip notifications for sender's own messages
  FOR chat_participant IN (
    SELECT user_id FROM public.chat_participants 
    WHERE chat_id = NEW.chat_id AND user_id != NEW.sender_id
  ) LOOP
    -- Get the sender's name
    DECLARE
      sender_name TEXT;
      chat_name TEXT;
    BEGIN
      SELECT first_name || ' ' || last_name INTO sender_name
      FROM public.profiles
      WHERE id = NEW.sender_id;
      
      SELECT name INTO chat_name
      FROM public.chats
      WHERE id = NEW.chat_id;
      
      -- Create a notification for each chat participant
      INSERT INTO public.notifications (
        user_id, 
        title, 
        body, 
        notification_type, 
        entity_type, 
        entity_id, 
        action_url
      )
      VALUES (
        chat_participant.user_id,
        'New message from ' || sender_name,
        CASE 
          WHEN NEW.type = 'text' THEN 
            LEFT(NEW.content, 50) || CASE WHEN LENGTH(NEW.content) > 50 THEN '...' ELSE '' END
          ELSE 
            CASE 
              WHEN NEW.type = 'image' THEN 'Image attachment'
              WHEN NEW.type = 'video' THEN 'Video attachment'
              WHEN NEW.type = 'audio' THEN 'Audio attachment'
              WHEN NEW.type = 'file' THEN 'File attachment'
              ELSE 'New message'
            END
        END,
        'new_message',
        'message',
        NEW.id,
        '/chats/' || NEW.chat_id
      );
    END;
  END LOOP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new message notifications
CREATE TRIGGER trigger_new_message_notification
AFTER INSERT ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.handle_new_message();

-- Function to update message counter in chats
CREATE OR REPLACE FUNCTION public.update_message_counter() 
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.chat_participants
  SET unread_count = unread_count + 1
  WHERE chat_id = NEW.chat_id AND user_id != NEW.sender_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update message counter
CREATE TRIGGER trigger_update_message_counter
AFTER INSERT ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.update_message_counter();

-- Function to reset unread counter when chat is read
CREATE OR REPLACE FUNCTION public.handle_chat_read() 
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.last_read_at IS NOT NULL AND OLD.last_read_at IS DISTINCT FROM NEW.last_read_at THEN
    NEW.unread_count = 0;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to reset unread counter
CREATE TRIGGER trigger_reset_unread_counter
BEFORE UPDATE ON public.chat_participants
FOR EACH ROW EXECUTE FUNCTION public.handle_chat_read();

-- Function to create notifications for new appointments
CREATE OR REPLACE FUNCTION public.handle_new_appointment() 
RETURNS TRIGGER AS $$
DECLARE
  provider_name TEXT;
BEGIN
  -- Get provider name
  SELECT first_name || ' ' || last_name INTO provider_name
  FROM public.profiles
  WHERE id = NEW.provider_id;

  -- Create notification for patient
  INSERT INTO public.notifications (
    user_id, 
    title, 
    body, 
    notification_type, 
    entity_type, 
    entity_id, 
    action_url
  )
  VALUES (
    NEW.patient_id,
    'New Appointment Scheduled',
    'You have a new appointment with ' || provider_name || ' on ' || 
    to_char(NEW.appointment_date, 'Mon DD, YYYY') || ' at ' || 
    to_char(NEW.appointment_time, 'HH12:MI AM'),
    'appointment_created',
    'appointment',
    NEW.id,
    '/appointments/' || NEW.id
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new appointment notifications
CREATE TRIGGER trigger_new_appointment_notification
AFTER INSERT ON public.appointments
FOR EACH ROW EXECUTE FUNCTION public.handle_new_appointment();

-- Function for appointment reminder notifications (would be called by a CRON job)
CREATE OR REPLACE FUNCTION public.send_appointment_reminders() 
RETURNS void AS $$
DECLARE
  appointment RECORD;
  provider_name TEXT;
BEGIN
  -- Find appointments happening tomorrow
  FOR appointment IN (
    SELECT * FROM public.appointments 
    WHERE appointment_date = CURRENT_DATE + 1
    AND status = 'scheduled'
  ) LOOP
    -- Get provider name
    SELECT first_name || ' ' || last_name INTO provider_name
    FROM public.profiles
    WHERE id = appointment.provider_id;
    
    -- Create reminder notification
    INSERT INTO public.notifications (
      user_id, 
      title, 
      body, 
      notification_type, 
      entity_type, 
      entity_id, 
      action_url
    )
    VALUES (
      appointment.patient_id,
      'Appointment Reminder',
      'Reminder: You have an appointment with ' || provider_name || ' tomorrow at ' || 
      to_char(appointment.appointment_time, 'HH12:MI AM'),
      'appointment_reminder',
      'appointment',
      appointment.id,
      '/appointments/' || appointment.id
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update BMI when height or weight changes
CREATE OR REPLACE FUNCTION public.update_bmi() 
RETURNS TRIGGER AS $$
DECLARE
  height DECIMAL;
  weight DECIMAL;
  bmi DECIMAL;
  is_weight_metric BOOLEAN;
BEGIN
  -- Check if this is a weight metric update
  SELECT EXISTS(
    SELECT 1 FROM public.health_metrics
    WHERE id = NEW.metric_id AND name = 'Weight'
  ) INTO is_weight_metric;
  
  -- Only proceed if this is a weight metric
  IF is_weight_metric THEN
    -- Get the latest height and weight
    SELECT height_cm INTO height
    FROM public.patient_records
    WHERE patient_id = NEW.patient_id;
    
    -- We already have the weight value in the NEW record
    weight := NEW.value;
    
    -- If both height and weight are available, calculate and store BMI
    IF height IS NOT NULL AND weight IS NOT NULL AND height > 0 THEN
      bmi := weight / ((height / 100) * (height / 100));
      
      -- Check if the patient has a risk assessment, update it
      UPDATE public.ncd_risk_assessments
      SET bmi = bmi, updated_at = now()
      WHERE patient_id = NEW.patient_id
      AND assessment_date = (
        SELECT MAX(assessment_date)
        FROM public.ncd_risk_assessments
        WHERE patient_id = NEW.patient_id
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update BMI when tracking entries change
CREATE TRIGGER trigger_update_bmi_on_tracking_change
AFTER INSERT OR UPDATE ON public.health_tracking_entries
FOR EACH ROW
EXECUTE FUNCTION public.update_bmi();

-- Function to automatically create chat for new appointments
CREATE OR REPLACE FUNCTION public.create_appointment_chat() 
RETURNS TRIGGER AS $$
DECLARE
  new_chat_id UUID;
BEGIN
  -- Create a new chat
  INSERT INTO public.chats (type, name, created_by, is_active)
  VALUES ('direct', 'Appointment Chat', NEW.provider_id, true)
  RETURNING id INTO new_chat_id;
  
  -- Add the patient and provider as participants
  INSERT INTO public.chat_participants (chat_id, user_id, role)
  VALUES 
    (new_chat_id, NEW.patient_id, 'member'),
    (new_chat_id, NEW.provider_id, 'owner');
    
  -- Add first system message
  INSERT INTO public.messages (chat_id, sender_id, type, content)
  VALUES (
    new_chat_id, 
    NEW.provider_id, 
    'text', 
    'This chat was automatically created for your appointment on ' || 
    to_char(NEW.appointment_date, 'Mon DD, YYYY') || ' at ' || 
    to_char(NEW.appointment_time, 'HH12:MI AM') || '. You can use this chat to communicate about the appointment.'
  );
  
  -- Store the chat ID in appointment metadata
  -- This assumes you have a metadata column in appointments table
  -- If not, this part can be modified or removed
  -- NEW.metadata = jsonb_set(COALESCE(NEW.metadata, '{}'::jsonb), '{chat_id}', to_jsonb(new_chat_id));
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create chat when appointment is created
CREATE TRIGGER trigger_create_appointment_chat
AFTER INSERT ON public.appointments
FOR EACH ROW
WHEN (NEW.status = 'scheduled')
EXECUTE FUNCTION public.create_appointment_chat();

-- Function to track user activity
CREATE OR REPLACE FUNCTION public.track_user_activity() 
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET last_seen = now(), is_online = true
  WHERE id = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to anonymize deleted user data
CREATE OR REPLACE FUNCTION public.anonymize_deleted_user() 
RETURNS TRIGGER AS $$
BEGIN
  -- Don't actually delete the user data, just anonymize it
  UPDATE public.profiles
  SET 
    first_name = 'Deleted',
    last_name = 'User',
    phone_number = NULL,
    avatar_url = NULL,
    bio = NULL,
    is_online = false,
    deleted_at = now()
  WHERE id = OLD.id;
  
  -- Mark the user's messages as from a deleted user
  UPDATE public.messages
  SET metadata = jsonb_set(COALESCE(metadata, '{}'::jsonb), '{deleted_user}', 'true')
  WHERE sender_id = OLD.id;
  
  RETURN NULL; -- Prevents the actual deletion
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for anonymizing deleted user
CREATE TRIGGER trigger_anonymize_deleted_user
BEFORE DELETE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.anonymize_deleted_user();

-- Function to update post counters when a comment is added
CREATE OR REPLACE FUNCTION public.update_post_comment_counter() 
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.content_type = 'community_post' THEN
    UPDATE public.community_posts
    SET comment_count = comment_count + 1
    WHERE id = NEW.content_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update post counters
CREATE TRIGGER trigger_update_post_comment_counter
AFTER INSERT ON public.comments
FOR EACH ROW EXECUTE FUNCTION public.update_post_comment_counter();

-- Function to update post like counters
CREATE OR REPLACE FUNCTION public.update_post_like_counter() 
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.content_type = 'community_post' AND NEW.reaction_type = 'like' THEN
    UPDATE public.community_posts
    SET like_count = like_count + 1
    WHERE id = NEW.content_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update post like counters
CREATE TRIGGER trigger_update_post_like_counter
AFTER INSERT ON public.content_reactions
FOR EACH ROW EXECUTE FUNCTION public.update_post_like_counter();

-- =============================================================================
-- SUPABASE STORAGE SETUP
-- =============================================================================

-- Create the necessary storage buckets and policies
-- NOTE: These commands must be executed manually in the Supabase dashboard 
-- or via the API since they are not standard PostgreSQL commands.
-- The following is pseudo-code to guide you on what to create in Supabase:

/*

# Create storage buckets for different attachment types
1. Create bucket: message_attachments (public)
2. Create bucket: post_attachments (public)
3. Create bucket: user_avatars (public)
4. Create bucket: medical_records (private)

# Storage RLS policies for message_attachments bucket:

-- Allow users to select message attachments they can access
CREATE POLICY "Users can view message attachments in chats they participate in"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'message_attachments' AND
  EXISTS (
    SELECT 1 FROM public.message_attachments ma
    JOIN public.messages m ON ma.message_id = m.id
    JOIN public.chat_participants cp ON m.chat_id = cp.chat_id
    WHERE cp.user_id = auth.uid() 
    AND storage.filename(name) = storage.filename(ma.storage_path)
  )
);

-- Allow users to upload message attachments
CREATE POLICY "Users can upload message attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'message_attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own message attachments
CREATE POLICY "Users can delete their own message attachments"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'message_attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

# Storage RLS policies for post_attachments bucket:

-- Allow users to select public post attachments
CREATE POLICY "Anyone can view post attachments"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'post_attachments');

-- Allow users to upload post attachments
CREATE POLICY "Users can upload post attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'post_attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own post attachments
CREATE POLICY "Users can delete their own post attachments"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'post_attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

# Storage RLS policies for user_avatars bucket:

-- Allow anyone to view user avatars
CREATE POLICY "Anyone can view user avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'user_avatars');

-- Allow users to upload their own avatar
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user_avatars' AND
  name LIKE auth.uid() || '/%'
);

-- Allow users to update their own avatar
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user_avatars' AND
  name LIKE auth.uid() || '/%'
);

# Storage RLS policies for medical_records bucket:

-- Allow patients to view their own medical records
CREATE POLICY "Patients can view their own medical records"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'medical_records' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow healthcare providers to view patient medical records
CREATE POLICY "Healthcare providers can view patient medical records"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'medical_records' AND
  EXISTS (
    SELECT 1 FROM public.healthcare_providers
    WHERE id = auth.uid()
  )
);

-- Allow healthcare providers to upload medical records
CREATE POLICY "Healthcare providers can upload medical records"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'medical_records' AND
  EXISTS (
    SELECT 1 FROM public.healthcare_providers
    WHERE id = auth.uid()
  )
);

*/

-- =============================================================================
-- DATABASE MAINTENANCE
-- =============================================================================

-- Function to clean up expired sessions and temporary data
CREATE OR REPLACE FUNCTION public.cleanup_expired_data()
RETURNS void AS $$
BEGIN
  -- Delete expired user verification tokens
  DELETE FROM public.user_verifications
  WHERE token_expires_at < now();
  
  -- Clean up typing status older than 5 minutes (they're probably not typing anymore)
  DELETE FROM public.typing_status
  WHERE updated_at < now() - interval '5 minutes' AND is_typing = true;
  
  -- Mark users as offline if they haven't been active for 10 minutes
  UPDATE public.profiles
  SET is_online = false
  WHERE is_online = true AND last_seen < now() - interval '10 minutes';
  
  -- Other maintenance tasks can be added here
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- FINAL SETUP
-- =============================================================================

-- Create default chat for system announcements
DO $$
DECLARE
  admin_id UUID;
  system_chat_id UUID;
BEGIN
  -- Find an admin user or use the first user
  SELECT id INTO admin_id FROM public.profiles LIMIT 1;
  
  -- Only proceed if we have an admin or user available
  IF admin_id IS NOT NULL THEN
    -- Create system announcement chat
    INSERT INTO public.chats (type, name, description, created_by, is_active)
    VALUES ('channel', 'System Announcements', 'Important system announcements and updates', admin_id, true)
    RETURNING id INTO system_chat_id;
    
    -- Add initial welcome message
    INSERT INTO public.messages (chat_id, sender_id, type, content)
    VALUES (
      system_chat_id,
      admin_id,
      'text',
      'Welcome to the NCD App! This channel will be used for important announcements and updates. Stay tuned for more information.'
    );
  END IF;
END;
$$ LANGUAGE plpgsql;