# Medical Readings Database Schema

## SQL Setup for Supabase

Run the following SQL commands in your Supabase SQL editor (Dashboard > SQL Editor) to set up the patient readings functionality:

```sql
-- =============================================
-- Patient Readings Table Setup
-- =============================================

-- Create the patient_readings table
CREATE TABLE IF NOT EXISTS public.patient_readings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID,
    name TEXT NOT NULL,
    age TEXT DEFAULT '',
    blood_pressure TEXT DEFAULT '',
    heart_rate TEXT DEFAULT '',
    respiratory_rate TEXT DEFAULT '',
    temperature TEXT DEFAULT '',
    height TEXT DEFAULT '',
    weight TEXT DEFAULT '',
    bmi TEXT DEFAULT '',
    fasting_blood_glucose TEXT DEFAULT '',
    random_blood_glucose TEXT DEFAULT '',
    hba1c TEXT DEFAULT '',
    lipid_profile TEXT DEFAULT '',
    serum_creatinine TEXT DEFAULT '',
    blood_urea_nitrogen TEXT DEFAULT '',
    egfr TEXT DEFAULT '',
    electrolytes TEXT DEFAULT '',
    liver_function_tests TEXT DEFAULT '',
    echocardiography TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    entered_by UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- =============================================
-- Indexes for Performance
-- =============================================

-- Index for patient name searching (case-insensitive)
CREATE INDEX IF NOT EXISTS idx_patient_readings_name_gin 
ON public.patient_readings USING gin(to_tsvector('english', name));

-- Index for name prefix/suffix searching
CREATE INDEX IF NOT EXISTS idx_patient_readings_name_trigram 
ON public.patient_readings USING gin(name gin_trgm_ops);

-- Index for date-based queries
CREATE INDEX IF NOT EXISTS idx_patient_readings_created_at 
ON public.patient_readings (created_at DESC);

-- Index for user-based queries
CREATE INDEX IF NOT EXISTS idx_patient_readings_entered_by 
ON public.patient_readings (entered_by);

-- Composite index for patient-specific queries
CREATE INDEX IF NOT EXISTS idx_patient_readings_name_date 
ON public.patient_readings (name, created_at DESC);

-- =============================================
-- Row Level Security (RLS) Setup
-- =============================================

-- Enable RLS on the table
ALTER TABLE public.patient_readings ENABLE ROW LEVEL SECURITY;

-- Policy for medical personnel to insert readings
CREATE POLICY "medical_personnel_can_insert" ON public.patient_readings
FOR INSERT 
TO authenticated
WITH CHECK (
    auth.jwt() ->> 'role' IN ('medical_personnel', 'doctor', 'admin') OR
    auth.jwt() -> 'user_metadata' ->> 'role' IN ('medical_personnel', 'doctor', 'admin')
);

-- Policy for doctors and medical personnel to view all readings
CREATE POLICY "healthcare_staff_can_view_all" ON public.patient_readings
FOR SELECT 
TO authenticated
USING (
    auth.jwt() ->> 'role' IN ('doctor', 'medical_personnel', 'admin') OR
    auth.jwt() -> 'user_metadata' ->> 'role' IN ('doctor', 'medical_personnel', 'admin')
);

-- Policy for users to view their own entered readings
CREATE POLICY "users_can_view_own_readings" ON public.patient_readings
FOR SELECT 
TO authenticated
USING (auth.uid() = entered_by);

-- Policy for medical personnel to update readings they entered
CREATE POLICY "medical_personnel_can_update_own" ON public.patient_readings
FOR UPDATE 
TO authenticated
USING (
    auth.uid() = entered_by AND 
    (
        auth.jwt() ->> 'role' IN ('medical_personnel', 'doctor', 'admin') OR
        auth.jwt() -> 'user_metadata' ->> 'role' IN ('medical_personnel', 'doctor', 'admin')
    )
);

-- Policy for authorized personnel to delete readings
CREATE POLICY "authorized_can_delete" ON public.patient_readings
FOR DELETE 
TO authenticated
USING (
    (auth.uid() = entered_by) OR
    (
        auth.jwt() ->> 'role' IN ('doctor', 'admin') OR
        auth.jwt() -> 'user_metadata' ->> 'role' IN ('doctor', 'admin')
    )
);

-- =============================================
-- Triggers for Automatic Updates
-- =============================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update the updated_at column
CREATE TRIGGER update_patient_readings_updated_at
    BEFORE UPDATE ON public.patient_readings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- Helper Functions
-- =============================================

-- Function to get distinct patient names for autocomplete
CREATE OR REPLACE FUNCTION get_patient_names(search_term TEXT DEFAULT '')
RETURNS TABLE(name TEXT) AS $$
BEGIN
    IF search_term = '' THEN
        RETURN QUERY
        SELECT DISTINCT pr.name
        FROM public.patient_readings pr
        WHERE pr.name IS NOT NULL AND pr.name != ''
        ORDER BY pr.name
        LIMIT 20;
    ELSE
        RETURN QUERY
        SELECT DISTINCT pr.name
        FROM public.patient_readings pr
        WHERE pr.name ILIKE '%' || search_term || '%'
        AND pr.name IS NOT NULL AND pr.name != ''
        ORDER BY pr.name
        LIMIT 20;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get reading statistics
CREATE OR REPLACE FUNCTION get_readings_statistics()
RETURNS JSON AS $$
DECLARE
    total_count INTEGER;
    recent_count INTEGER;
    unique_patients INTEGER;
    result JSON;
BEGIN
    -- Get total readings count
    SELECT COUNT(*) INTO total_count FROM public.patient_readings;
    
    -- Get readings from last 30 days
    SELECT COUNT(*) INTO recent_count 
    FROM public.patient_readings 
    WHERE created_at >= NOW() - INTERVAL '30 days';
    
    -- Get unique patients count
    SELECT COUNT(DISTINCT name) INTO unique_patients 
    FROM public.patient_readings 
    WHERE name IS NOT NULL AND name != '';
    
    -- Build result JSON
    SELECT json_build_object(
        'totalReadings', total_count,
        'recentReadings', recent_count,
        'uniquePatients', unique_patients,
        'generatedAt', NOW()
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- Audit Table (Optional)
-- =============================================

-- Table to track changes for compliance
CREATE TABLE IF NOT EXISTS public.patient_readings_audit (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reading_id UUID NOT NULL,
    action TEXT NOT NULL, -- INSERT, UPDATE, DELETE
    old_data JSONB,
    new_data JSONB,
    changed_by UUID REFERENCES auth.users(id),
    changed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Function to log changes
CREATE OR REPLACE FUNCTION log_patient_reading_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO public.patient_readings_audit (reading_id, action, old_data, changed_by)
        VALUES (OLD.id, 'DELETE', to_jsonb(OLD), auth.uid());
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.patient_readings_audit (reading_id, action, old_data, new_data, changed_by)
        VALUES (NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), auth.uid());
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO public.patient_readings_audit (reading_id, action, new_data, changed_by)
        VALUES (NEW.id, 'INSERT', to_jsonb(NEW), auth.uid());
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Audit trigger
CREATE TRIGGER patient_readings_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON public.patient_readings
    FOR EACH ROW EXECUTE FUNCTION log_patient_reading_changes();

-- =============================================
-- Real-time Subscriptions Setup
-- =============================================

-- Enable realtime for the table
ALTER PUBLICATION supabase_realtime ADD TABLE public.patient_readings;

-- =============================================
-- Sample Data (Optional - for testing)
-- =============================================

-- Insert sample readings (uncomment if needed for testing)
/*
INSERT INTO public.patient_readings (
    name, age, blood_pressure, heart_rate, temperature, height, weight, bmi,
    entered_by
) VALUES 
    ('John Doe', '45', '120/80', '72', '98.6°F', '175', '70', '22.9', auth.uid()),
    ('Jane Smith', '38', '110/70', '68', '97.8°F', '165', '60', '22.0', auth.uid()),
    ('Michael Johnson', '52', '130/85', '75', '99.1°F', '180', '85', '26.2', auth.uid());
*/

-- =============================================
-- Verification Queries
-- =============================================

-- Check if table was created successfully
-- SELECT * FROM information_schema.tables WHERE table_name = 'patient_readings';

-- Check indexes
-- SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'patient_readings';

-- Check RLS policies
-- SELECT * FROM pg_policies WHERE tablename = 'patient_readings';

-- Test the helper functions
-- SELECT * FROM get_patient_names();
-- SELECT get_readings_statistics();
```

## Additional Setup Notes

### 1. Enable Required Extensions

Make sure these PostgreSQL extensions are enabled in your Supabase project:

```sql
-- Enable extensions for better search functionality
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
```

### 2. User Role Setup

For proper role-based access, ensure your users have the correct metadata:

```sql
-- Example: Set user role (run this for each medical personnel)
UPDATE auth.users 
SET raw_user_meta_data = raw_user_meta_data || '{"role": "medical_personnel"}'::jsonb
WHERE email = 'nurse@hospital.com';

-- Example: Set doctor role
UPDATE auth.users 
SET raw_user_meta_data = raw_user_meta_data || '{"role": "doctor"}'::jsonb
WHERE email = 'doctor@hospital.com';
```

### 3. Performance Optimization

For large datasets, consider:

- Partitioning by date if you expect millions of records
- Regular VACUUM and ANALYZE operations
- Connection pooling configuration

### 4. Security Considerations

- All fields store data as TEXT to support flexible input formats
- RLS policies ensure data privacy and role-based access
- Audit logging tracks all changes for compliance
- Real-time subscriptions are enabled for live updates

### 5. Backup Strategy

Set up regular backups and point-in-time recovery:

- Enable automated backups in Supabase dashboard
- Consider periodic exports for critical data
- Test restoration procedures regularly

This schema provides a robust foundation for medical readings management with proper security, performance, and audit capabilities.