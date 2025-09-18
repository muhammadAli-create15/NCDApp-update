# Supabase Setup Guide

## Overview
This project has been migrated from Django to use Supabase as the backend. Follow this guide to set up your Supabase project and configure the Flutter app.

## 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Create a new project
3. Choose your organization and project name
4. Select a region close to your users
5. Set a database password (save this securely)
6. Wait for the project to be created (2-3 minutes)

## 2. Configure Environment Variables

1. Copy the example environment file:
   ```
   cp .env.example .env
   ```

2. Get your Supabase credentials:
   - Go to your Supabase project dashboard
   - Navigate to Settings > API
   - Copy the Project URL and anon public key

3. Update your `.env` file with your actual credentials:
   ```
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

   **Important:** Replace the entire URL and key with your actual values from Supabase.

## 3. Database Setup

Run these SQL commands in the Supabase SQL editor (Dashboard > SQL Editor):

```sql
-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- Create tables
CREATE TABLE public.readings (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    reading_type VARCHAR(50) NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    unit VARCHAR(20),
    notes TEXT,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.appointments (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    appointment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(200),
    doctor_name VARCHAR(100),
    status VARCHAR(20) DEFAULT 'scheduled',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.medications (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    dosage VARCHAR(100),
    frequency VARCHAR(100),
    start_date DATE,
    end_date DATE,
    notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.alerts (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    alert_type VARCHAR(50) DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own readings" ON public.readings
    FOR SELECT USING (auth.uid() = user_id);
    
CREATE POLICY "Users can insert their own readings" ON public.readings
    FOR INSERT WITH CHECK (auth.uid() = user_id);
    
CREATE POLICY "Users can update their own readings" ON public.readings
    FOR UPDATE USING (auth.uid() = user_id);
    
CREATE POLICY "Users can delete their own readings" ON public.readings
    FOR DELETE USING (auth.uid() = user_id);

-- Similar policies for other tables
CREATE POLICY "Users can manage their own appointments" ON public.appointments
    FOR ALL USING (auth.uid() = user_id);
    
CREATE POLICY "Users can manage their own medications" ON public.medications
    FOR ALL USING (auth.uid() = user_id);
    
CREATE POLICY "Users can manage their own alerts" ON public.alerts
    FOR ALL USING (auth.uid() = user_id);
```

## 4. Authentication Setup

1. In your Supabase dashboard, go to Authentication > Settings
2. Configure your site URL (for development: `http://localhost:3000`)
3. Add redirect URLs if needed
4. Enable email confirmation if desired

## 5. Test the Setup

1. Run `flutter pub get` to install dependencies
2. Start the Flutter app: `flutter run`
3. Try creating an account and logging in
4. Test creating and viewing health readings

## 6. Security Notes

- Your `.env` file is automatically ignored by git (listed in `.gitignore`)
- Never commit your Supabase credentials to version control
- The anon key is safe to use in client-side code as it respects RLS policies
- Consider using service role key only for server-side operations (not in this mobile app)

## 7. Next Steps

- Customize the database schema as needed
- Set up real-time subscriptions for live data updates
- Configure push notifications
- Set up proper error handling and loading states
- Add data validation and sanitization

## Troubleshooting

### App won't start
- Check that your `.env` file has the correct Supabase URL and anon key
- Ensure the `.env` file is in the root of the `mobile_flutter` folder
- Verify that `flutter pub get` completed successfully

### Authentication issues
- Check your Supabase project's authentication settings
- Ensure email templates are configured
- Verify RLS policies are set up correctly

### Database errors
- Check that all tables are created
- Verify RLS policies are applied
- Ensure the user has proper permissions