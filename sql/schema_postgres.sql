-- Postgres/Supabase schema for NCDApp
-- Run this in Supabase SQL editor or psql connected to your database
-- Safe to run multiple times (uses IF NOT EXISTS where possible)

-- Extensions (Supabase has these, but keep for local Postgres)
create extension if not exists pgcrypto;

-- Use public schema
set search_path = public;

-- Enumerations
create type role_type as enum ('patient','doctor','staff','admin');
create type reading_type as enum (
  'blood_glucose', 'blood_pressure', 'weight', 'height', 'bmi', 'waist',
  'pulse', 'temperature', 'spo2', 'other'
);
create type appointment_status as enum ('scheduled','completed','canceled');
create type med_log_status as enum ('taken','missed','skipped');
create type input_type as enum ('boolean','number','text','choice');
create type risk_method as enum ('rule','ml','ada');

-- Generic updated_at trigger
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end; $$ language plpgsql;

-- Profiles extend auth.users (Supabase)
create table if not exists profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  role role_type not null default 'patient',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger trg_profiles_updated before update on profiles
for each row execute procedure set_updated_at();
create index if not exists idx_profiles_role on profiles(role);

-- Ensure a profile row exists for each auth user
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, metadata)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', null),
    coalesce(new.raw_user_meta_data, '{}'::jsonb)
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Keep profiles in sync if auth.users metadata/full_name changes
create or replace function public.handle_user_updated()
returns trigger as $$
begin
  update public.profiles p
     set full_name = coalesce(new.raw_user_meta_data->>'full_name', p.full_name),
         metadata  = coalesce(new.raw_user_meta_data, p.metadata),
         updated_at = now()
   where p.id = new.id;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_updated on auth.users;
create trigger on_auth_user_updated
  after update on auth.users
  for each row execute procedure public.handle_user_updated();

-- Patient readings with typed fields (flexible but typed columns)
create table if not exists patient_readings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  type reading_type not null,
  measured_at timestamptz not null default now(),
  -- Blood pressure
  systolic int,
  diastolic int,
  -- Glucose
  glucose_mg_dl numeric(6,2),
  -- Anthropometrics
  weight_kg numeric(6,2),
  height_cm numeric(5,2),
  bmi numeric(5,2),
  waist_cm numeric(5,2),
  -- Vitals
  pulse_bpm int,
  temperature_c numeric(4,1),
  spo2 int,
  -- Misc
  notes text,
  source text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chk_bp_valid check (
    (systolic is null or (systolic between 50 and 260)) and
    (diastolic is null or (diastolic between 30 and 180))
  ),
  constraint chk_glucose_valid check (
    glucose_mg_dl is null or glucose_mg_dl between 20 and 1000
  ),
  constraint chk_weight_valid check (
    weight_kg is null or weight_kg between 2 and 500
  ),
  constraint chk_height_valid check (
    height_cm is null or height_cm between 30 and 300
  ),
  constraint chk_bmi_valid check (
    bmi is null or bmi between 5 and 100
  ),
  constraint chk_waist_valid check (
    waist_cm is null or waist_cm between 10 and 300
  ),
  constraint chk_pulse_valid check (
    pulse_bpm is null or pulse_bpm between 20 and 250
  ),
  constraint chk_temp_valid check (
    temperature_c is null or temperature_c between 25 and 45
  ),
  constraint chk_spo2_valid check (
    spo2 is null or spo2 between 50 and 100
  )
);
create trigger trg_readings_updated before update on patient_readings
for each row execute procedure set_updated_at();
create index if not exists idx_patient_readings_user on patient_readings(user_id);
create index if not exists idx_patient_readings_type on patient_readings(type);
create index if not exists idx_patient_readings_measured on patient_readings(measured_at desc);

-- Medications and logs
create table if not exists medications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  dosage text,
  frequency text,
  reminder_time time,
  is_active boolean not null default true,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger trg_meds_updated before update on medications
for each row execute procedure set_updated_at();
create index if not exists idx_meds_user on medications(user_id);

create table if not exists medication_logs (
  id uuid primary key default gen_random_uuid(),
  medication_id uuid not null references medications(id) on delete cascade,
  taken_at timestamptz not null default now(),
  status med_log_status not null default 'taken',
  notes text
);
create index if not exists idx_med_logs_med on medication_logs(medication_id);
create index if not exists idx_med_logs_taken on medication_logs(taken_at desc);

-- Notifications (in-app)
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  body text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_notifications_user on notifications(user_id);
create index if not exists idx_notifications_created on notifications(created_at desc);

-- Education content
create table if not exists education_topics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique,
  created_at timestamptz not null default now()
);

create table if not exists education_items (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  url text,
  content text,
  topic_id uuid references education_topics(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists idx_education_items_topic on education_items(topic_id);

create table if not exists user_education_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  item_id uuid not null references education_items(id) on delete cascade,
  completed_at timestamptz not null default now(),
  unique(user_id, item_id)
);
create index if not exists idx_edu_progress_user on user_education_progress(user_id);

-- Questionnaires
create table if not exists questionnaire_templates (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists questionnaire_questions (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references questionnaire_templates(id) on delete cascade,
  order_index int not null default 0,
  question_text text not null,
  input input_type not null default 'text'
);
create index if not exists idx_qq_template on questionnaire_questions(template_id);

create table if not exists questionnaire_choices (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references questionnaire_questions(id) on delete cascade,
  choice_text text not null,
  value int
);
create index if not exists idx_qc_question on questionnaire_choices(question_id);

create table if not exists questionnaire_responses (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references questionnaire_templates(id) on delete restrict,
  user_id uuid not null references profiles(id) on delete cascade,
  submitted_at timestamptz not null default now()
);
create index if not exists idx_qr_user on questionnaire_responses(user_id);

create table if not exists questionnaire_response_items (
  id uuid primary key default gen_random_uuid(),
  response_id uuid not null references questionnaire_responses(id) on delete cascade,
  question_id uuid not null references questionnaire_questions(id) on delete restrict,
  answer_text text,
  answer_number numeric,
  answer_bool boolean,
  choice_id uuid references questionnaire_choices(id) on delete set null,
  raw jsonb
);
create index if not exists idx_qri_response on questionnaire_response_items(response_id);

-- Quizzes
create table if not exists quizzes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  created_at timestamptz not null default now()
);

create table if not exists quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references quizzes(id) on delete cascade,
  order_index int not null default 0,
  question_text text not null
);
create index if not exists idx_qq_quiz on quiz_questions(quiz_id);

create table if not exists quiz_choices (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references quiz_questions(id) on delete cascade,
  choice_text text not null,
  is_correct boolean not null default false
);
create index if not exists idx_qc_question2 on quiz_choices(question_id);

create table if not exists quiz_responses (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references quizzes(id) on delete restrict,
  user_id uuid not null references profiles(id) on delete cascade,
  submitted_at timestamptz not null default now(),
  score int,
  total int,
  explanations jsonb,
  education_suggestions jsonb
);
create index if not exists idx_qr2_user on quiz_responses(user_id);

-- Support groups
create table if not exists support_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists support_group_memberships (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references support_groups(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  role role_type not null default 'patient',
  joined_at timestamptz not null default now(),
  unique(group_id, user_id)
);
create index if not exists idx_sgm_group on support_group_memberships(group_id);
create index if not exists idx_sgm_user on support_group_memberships(user_id);

create table if not exists support_group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references support_groups(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  message text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_sgmsg_group on support_group_messages(group_id);

-- Appointments
create table if not exists appointments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  scheduled_for timestamptz not null,
  doctor text,
  status appointment_status not null default 'scheduled',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger trg_appt_updated before update on appointments
for each row execute procedure set_updated_at();
create index if not exists idx_appt_user on appointments(user_id);
create index if not exists idx_appt_time on appointments(scheduled_for desc);

-- Risk assessments
create table if not exists risk_assessments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  method risk_method not null,
  score numeric(5,2),
  data jsonb,
  assessed_at timestamptz not null default now()
);
create index if not exists idx_risk_user on risk_assessments(user_id);
create index if not exists idx_risk_method on risk_assessments(method);

-- Basic analytics helpers (optional views)
create or replace view v_readings_latest as
select distinct on (user_id, type)
  user_id, type, measured_at, systolic, diastolic, glucose_mg_dl, weight_kg, height_cm, bmi, waist_cm, pulse_bpm, temperature_c, spo2, id
from patient_readings
order by user_id, type, measured_at desc;

-- Row Level Security (RLS) policies
-- Helper predicate: is staff/doctor
create or replace function is_staff(uid uuid)
returns boolean language sql stable as $$
  select exists (
    select 1 from profiles p where p.id = uid and p.role in ('doctor','staff','admin')
  );
$$;

-- Enable RLS on user-scoped tables
alter table profiles enable row level security;
alter table patient_readings enable row level security;
alter table medications enable row level security;
alter table medication_logs enable row level security;
alter table notifications enable row level security;
alter table user_education_progress enable row level security;
alter table questionnaire_responses enable row level security;
alter table questionnaire_response_items enable row level security;
alter table quiz_responses enable row level security;
alter table support_group_memberships enable row level security;
alter table support_group_messages enable row level security;
alter table appointments enable row level security;
alter table risk_assessments enable row level security;

-- Profiles
drop policy if exists "read own profile" on profiles;
create policy "read own profile" on profiles
for select using (auth.uid() = id or is_staff(auth.uid()));
drop policy if exists "update own profile" on profiles;
create policy "update own profile" on profiles
for update using (auth.uid() = id) with check (auth.uid() = id);

-- Generic policies for user_id tables: own rows + staff full access
drop policy if exists "own_select_readings" on patient_readings;
create policy "own_select_readings" on patient_readings
for select using (user_id = auth.uid() or is_staff(auth.uid()));
drop policy if exists "own_insert_readings" on patient_readings;
create policy "own_insert_readings" on patient_readings
for insert with check (user_id = auth.uid());
drop policy if exists "own_update_readings" on patient_readings;
create policy "own_update_readings" on patient_readings
for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "own_delete_readings" on patient_readings;
create policy "own_delete_readings" on patient_readings
for delete using (user_id = auth.uid());

drop policy if exists "own_select_meds" on medications;
create policy "own_select_meds" on medications
for select using (user_id = auth.uid() or is_staff(auth.uid()));
drop policy if exists "own_cud_meds" on medications;
create policy "own_cud_meds" on medications
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own_select_med_logs" on medication_logs;
create policy "own_select_med_logs" on medication_logs
for select using (exists (select 1 from medications m where m.id = medication_id and (m.user_id = auth.uid() or is_staff(auth.uid()))));
drop policy if exists "own_cud_med_logs" on medication_logs;
create policy "own_cud_med_logs" on medication_logs
for all using (exists (select 1 from medications m where m.id = medication_id and m.user_id = auth.uid()))
with check (exists (select 1 from medications m where m.id = medication_id and m.user_id = auth.uid()));

drop policy if exists "own_select_notifications" on notifications;
create policy "own_select_notifications" on notifications
for select using (user_id = auth.uid() or is_staff(auth.uid()));
drop policy if exists "own_cud_notifications" on notifications;
create policy "own_cud_notifications" on notifications
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own_select_edu_progress" on user_education_progress;
create policy "own_select_edu_progress" on user_education_progress
for select using (user_id = auth.uid() or is_staff(auth.uid()));
drop policy if exists "own_cud_edu_progress" on user_education_progress;
create policy "own_cud_edu_progress" on user_education_progress
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own_select_qr" on questionnaire_responses;
create policy "own_select_qr" on questionnaire_responses
for select using (user_id = auth.uid() or is_staff(auth.uid()));
drop policy if exists "own_cud_qr" on questionnaire_responses;
create policy "own_cud_qr" on questionnaire_responses
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own_select_qri" on questionnaire_response_items;
create policy "own_select_qri" on questionnaire_response_items
for select using (exists (select 1 from questionnaire_responses r where r.id = response_id and (r.user_id = auth.uid() or is_staff(auth.uid()))));
drop policy if exists "own_cud_qri" on questionnaire_response_items;
create policy "own_cud_qri" on questionnaire_response_items
for all using (exists (select 1 from questionnaire_responses r where r.id = response_id and r.user_id = auth.uid()))
with check (exists (select 1 from questionnaire_responses r where r.id = response_id and r.user_id = auth.uid()));

drop policy if exists "own_select_quiz_resp" on quiz_responses;
create policy "own_select_quiz_resp" on quiz_responses
for select using (user_id = auth.uid() or is_staff(auth.uid()));
drop policy if exists "own_cud_quiz_resp" on quiz_responses;
create policy "own_cud_quiz_resp" on quiz_responses
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own_select_sg_members" on support_group_memberships;
create policy "own_select_sg_members" on support_group_memberships
for select using (user_id = auth.uid() or is_staff(auth.uid()));
drop policy if exists "own_cud_sg_members" on support_group_memberships;
create policy "own_cud_sg_members" on support_group_memberships
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own_select_sg_msgs" on support_group_messages;
create policy "own_select_sg_msgs" on support_group_messages
for select using (
  user_id = auth.uid() or is_staff(auth.uid()) or
  exists (
    select 1 from support_group_memberships m
    where m.group_id = support_group_messages.group_id and m.user_id = auth.uid()
  )
);
drop policy if exists "own_insert_sg_msgs" on support_group_messages;
create policy "own_insert_sg_msgs" on support_group_messages
for insert with check (
  user_id = auth.uid() and exists (
    select 1 from support_group_memberships m
    where m.group_id = support_group_messages.group_id and m.user_id = auth.uid()
  )
);

drop policy if exists "own_select_appt" on appointments;
create policy "own_select_appt" on appointments
for select using (user_id = auth.uid() or is_staff(auth.uid()));
drop policy if exists "own_cud_appt" on appointments;
create policy "own_cud_appt" on appointments
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "own_select_risk" on risk_assessments;
create policy "own_select_risk" on risk_assessments
for select using (user_id = auth.uid() or is_staff(auth.uid()));
drop policy if exists "own_cud_risk" on risk_assessments;
create policy "own_cud_risk" on risk_assessments
for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Open read access (authenticated) to non-user-scoped reference data
alter table education_topics enable row level security;
alter table education_items enable row level security;
alter table questionnaire_templates enable row level security;
alter table questionnaire_questions enable row level security;
alter table questionnaire_choices enable row level security;
alter table quizzes enable row level security;
alter table quiz_questions enable row level security;
alter table quiz_choices enable row level security;
alter table support_groups enable row level security;

drop policy if exists "auth_read_topics" on education_topics; 
create policy "auth_read_topics" on education_topics for select using (auth.role() = 'authenticated');
drop policy if exists "auth_read_items" on education_items; 
create policy "auth_read_items" on education_items for select using (auth.role() = 'authenticated');
drop policy if exists "auth_read_q_templates" on questionnaire_templates; 
create policy "auth_read_q_templates" on questionnaire_templates for select using (auth.role() = 'authenticated');
drop policy if exists "auth_read_q_questions" on questionnaire_questions; 
create policy "auth_read_q_questions" on questionnaire_questions for select using (auth.role() = 'authenticated');
drop policy if exists "auth_read_q_choices" on questionnaire_choices; 
create policy "auth_read_q_choices" on questionnaire_choices for select using (auth.role() = 'authenticated');
drop policy if exists "auth_read_quizzes" on quizzes; 
create policy "auth_read_quizzes" on quizzes for select using (auth.role() = 'authenticated');
drop policy if exists "auth_read_qq" on quiz_questions; 
create policy "auth_read_qq" on quiz_questions for select using (auth.role() = 'authenticated');
drop policy if exists "auth_read_qc" on quiz_choices; 
create policy "auth_read_qc" on quiz_choices for select using (auth.role() = 'authenticated');
drop policy if exists "auth_read_groups" on support_groups; 
create policy "auth_read_groups" on support_groups for select using (auth.role() = 'authenticated');

-- Seed minimal roles/profile helper (optional)
-- insert into profiles (id, full_name, role) values ('00000000-0000-0000-0000-000000000000','Admin','admin') on conflict do nothing;

-- Done
