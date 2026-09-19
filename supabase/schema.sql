-- Khetha Go — Supabase Database Schema
-- Run this in your Supabase SQL Editor to create all tables.
-- RLS policies are included; enable RLS on each table.

-- ============================================================
-- UNIVERSITIES
-- ============================================================
create table if not exists universities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  abbreviation text,
  province text not null,
  type text not null check (type in ('university', 'university_of_technology', 'comprehensive')),
  website text,
  email text,
  phone text,
  address text,
  logo_url text,
  min_aps integer default 0,
  application_open_date date,
  application_close_date date,
  late_application_close_date date,
  accepts_clearing boolean default false,
  created_at timestamptz default now()
);

-- ============================================================
-- TVET COLLEGES
-- ============================================================
create table if not exists tvet_colleges (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  province text not null,
  campus text,
  website text,
  email text,
  phone text,
  address text,
  logo_url text,
  programmes_offered text[],
  nated_programmes boolean default true,
  nc_v_programmes boolean default true,
  occupational_programmes boolean default false,
  application_open_date date,
  application_close_date date,
  created_at timestamptz default now()
);

-- ============================================================
-- PROGRAMMES / QUALIFICATIONS
-- ============================================================
create table if not exists programmes (
  id uuid primary key default gen_random_uuid(),
  institution_id uuid references universities(id) on delete cascade,
  tvet_college_id uuid references tvet_colleges(id) on delete cascade,
  name text not null,
  qualification_type text not null check (qualification_type in (
    'higher_certificate', 'diploma', 'advanced_diploma',
    'bachelor', 'bachelor_honours', 'postgrad_diploma',
    'masters', 'doctorate',
    'nc_v', 'nated', 'occupational'
  )),
  field_of_study text not null,
  nqf_level integer not null check (nqf_level between 1 and 10),
  saqa_id text,
  duration text,
  aps_required integer default 0,
  pass_required text default 'bachelor' check (pass_required in ('higher_certificate', 'diploma', 'bachelor')),
  required_subjects jsonb default '[]',
  description text,
  career_outcomes text[],
  is_extended_programme boolean default false,
  articulates_to uuid[],
  application_fee numeric(10,2),
  created_at timestamptz default now(),
  check (institution_id is not null or tvet_college_id is not null)
);

-- ============================================================
-- CAREERS
-- ============================================================
create table if not exists careers (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  ofo_code text,
  sector text not null,
  description text not null,
  day_in_the_life text,
  required_subjects text[],
  helpful_subjects text[],
  traits text[],
  riasec jsonb not null default '{}',
  study_pathway text,
  min_qualification text,
  nqf_level text,
  entry_salary_band text,
  experienced_salary_band text,
  demand text default 'stable' check (demand in ('high', 'moderate', 'stable')),
  scarce_skill boolean default false,
  related_career_ids uuid[],
  created_at timestamptz default now()
);

-- ============================================================
-- BURSARIES
-- ============================================================
create table if not exists bursaries (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  provider text not null,
  description text not null,
  category text not null check (category in ('merit', 'need_based', 'field_specific', 'corporate', 'government')),
  fields_of_study text[],
  min_aps text,
  max_household_income text,
  closing_date text,
  website_url text,
  requirements text[],
  coverage_description text,
  application_link text,
  is_active boolean default true,
  year integer default extract(year from now()),
  created_at timestamptz default now()
);

-- ============================================================
-- SUBJECTS (reference table)
-- ============================================================
create table if not exists subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  is_language boolean default false,
  is_elective boolean default true,
  field_alignment text[],
  created_at timestamptz default now()
);

-- ============================================================
-- PROVINCES (reference table)
-- ============================================================
create table if not exists provinces (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  abbreviation text not null unique
);

-- ============================================================
-- SUPPORT RESOURCES
-- ============================================================
create table if not exists support_resources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text not null check (type in ('helpline', 'walk_in', 'online', 'whatsapp', 'email')),
  province text,
  phone text,
  email text,
  website text,
  whatsapp text,
  address text,
  operating_hours text,
  description text,
  is_national boolean default false,
  created_at timestamptz default now()
);

-- ============================================================
-- TUTORS
-- ============================================================
create table if not exists tutors (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  province text not null,
  subjects text[],
  rating numeric(2,1) default 0,
  hourly_rate numeric(10,2),
  bio text,
  contact_phone text,
  contact_email text,
  online_available boolean default false,
  in_person_available boolean default true,
  created_at timestamptz default now()
);

-- ============================================================
-- INTEREST QUESTIONS (for onboarding quiz)
-- ============================================================
create table if not exists interest_questions (
  id uuid primary key default gen_random_uuid(),
  question_text text not null,
  category text not null,
  riasec_dimension text check (riasec_dimension in ('R', 'I', 'A', 'S', 'E', 'C')),
  options jsonb not null default '[]',
  sort_order integer default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- All tables are read-only for anon (public data).
-- ============================================================
alter table universities enable row level security;
alter table tvet_colleges enable row level security;
alter table programmes enable row level security;
alter table careers enable row level security;
alter table bursaries enable row level security;
alter table subjects enable row level security;
alter table provinces enable row level security;
alter table support_resources enable row level security;
alter table tutors enable row level security;
alter table interest_questions enable row level security;

create policy "Public read universities" on universities for select using (true);
create policy "Public read tvet_colleges" on tvet_colleges for select using (true);
create policy "Public read programmes" on programmes for select using (true);
create policy "Public read careers" on careers for select using (true);
create policy "Public read bursaries" on bursaries for select using (true);
create policy "Public read subjects" on subjects for select using (true);
create policy "Public read provinces" on provinces for select using (true);
create policy "Public read support_resources" on support_resources for select using (true);
create policy "Public read tutors" on tutors for select using (true);
create policy "Public read interest_questions" on interest_questions for select using (true);

-- ============================================================
-- SEED DATA: South African Provinces
-- ============================================================
insert into provinces (name, abbreviation) values
  ('Eastern Cape', 'EC'),
  ('Free State', 'FS'),
  ('Gauteng', 'GP'),
  ('KwaZulu-Natal', 'KZN'),
  ('Limpopo', 'LP'),
  ('Mpumalanga', 'MP'),
  ('North West', 'NW'),
  ('Northern Cape', 'NC'),
  ('Western Cape', 'WC')
on conflict (name) do nothing;

-- ============================================================
-- SEED DATA: Subjects
-- ============================================================
insert into subjects (name, is_language, is_elective, field_alignment) values
  ('Mathematics', false, false, '{"Engineering & Technology", "Health Sciences", "Business & Finance", "Agriculture & Environment"}'),
  ('Mathematical Literacy', false, false, '{"Skilled Trades & Artisanship"}'),
  ('Physical Sciences', false, true, '{"Engineering & Technology", "Health Sciences"}'),
  ('Life Sciences', false, true, '{"Health Sciences", "Agriculture & Environment"}'),
  ('Accounting', false, true, '{"Business & Finance"}'),
  ('Business Studies', false, true, '{"Business & Finance"}'),
  ('Economics', false, true, '{"Business & Finance"}'),
  ('Geography', false, true, '{"Agriculture & Environment"}'),
  ('History', false, true, '{"Education & Social Development"}'),
  ('Information Technology', false, true, '{"Engineering & Technology", "Creative & Media"}'),
  ('Engineering Graphics & Design', false, true, '{"Engineering & Technology", "Skilled Trades & Artisanship"}'),
  ('Visual Arts', false, true, '{"Creative & Media"}'),
  ('Dramatic Arts', false, true, '{"Creative & Media"}'),
  ('Agricultural Sciences', false, true, '{"Agriculture & Environment"}'),
  ('Consumer Studies', false, true, '{}'),
  ('Tourism', false, true, '{}'),
  ('English', true, false, '{}'),
  ('Afrikaans', true, true, '{}'),
  ('isiZulu', true, true, '{}'),
  ('isiXhosa', true, true, '{}'),
  ('Sesotho', true, true, '{}'),
  ('Setswana', true, true, '{}'),
  ('Sepedi', true, true, '{}'),
  ('Tshivenda', true, true, '{}'),
  ('Xitsonga', true, true, '{}'),
  ('isiNdebele', true, true, '{}'),
  ('siSwati', true, true, '{}'),
  ('Life Orientation', false, false, '{}')
on conflict (name) do nothing;

-- ============================================================
-- SEED DATA: Universities
-- ============================================================
insert into universities (name, abbreviation, province, type, website, min_aps, accepts_clearing) values
  ('University of Cape Town', 'UCT', 'Western Cape', 'university', 'https://www.uct.ac.za', 34, true),
  ('University of the Witwatersrand', 'Wits', 'Gauteng', 'university', 'https://www.wits.ac.za', 32, true),
  ('Stellenbosch University', 'SU', 'Western Cape', 'university', 'https://www.sun.ac.za', 30, true),
  ('University of Pretoria', 'UP', 'Gauteng', 'university', 'https://www.up.ac.za', 28, true),
  ('University of KwaZulu-Natal', 'UKZN', 'KwaZulu-Natal', 'university', 'https://www.ukzn.ac.za', 28, true),
  ('University of Johannesburg', 'UJ', 'Gauteng', 'comprehensive', 'https://www.uj.ac.za', 26, true),
  ('University of the Free State', 'UFS', 'Free State', 'university', 'https://www.ufs.ac.za', 26, true),
  ('North-West University', 'NWU', 'North West', 'university', 'https://www.nwu.ac.za', 24, true),
  ('Nelson Mandela University', 'NMU', 'Eastern Cape', 'comprehensive', 'https://www.mandela.ac.za', 24, true),
  ('University of the Western Cape', 'UWC', 'Western Cape', 'university', 'https://www.uwc.ac.za', 24, true),
  ('Rhodes University', 'RU', 'Eastern Cape', 'university', 'https://www.ru.ac.za', 30, true),
  ('University of Limpopo', 'UL', 'Limpopo', 'university', 'https://www.ul.ac.za', 22, true),
  ('University of Venda', 'Univen', 'Limpopo', 'university', 'https://www.univen.ac.za', 22, true),
  ('University of Fort Hare', 'UFH', 'Eastern Cape', 'university', 'https://www.ufh.ac.za', 22, true),
  ('Walter Sisulu University', 'WSU', 'Eastern Cape', 'comprehensive', 'https://www.wsu.ac.za', 22, true),
  ('University of Zululand', 'UniZulu', 'KwaZulu-Natal', 'university', 'https://www.unizulu.ac.za', 22, true),
  ('Tshwane University of Technology', 'TUT', 'Gauteng', 'university_of_technology', 'https://www.tut.ac.za', 22, true),
  ('Cape Peninsula University of Technology', 'CPUT', 'Western Cape', 'university_of_technology', 'https://www.cput.ac.za', 22, true),
  ('Durban University of Technology', 'DUT', 'KwaZulu-Natal', 'university_of_technology', 'https://www.dut.ac.za', 22, true),
  ('Vaal University of Technology', 'VUT', 'Gauteng', 'university_of_technology', 'https://www.vut.ac.za', 20, true),
  ('Central University of Technology', 'CUT', 'Free State', 'university_of_technology', 'https://www.cut.ac.za', 20, true),
  ('Mangosuthu University of Technology', 'MUT', 'KwaZulu-Natal', 'university_of_technology', 'https://www.mut.ac.za', 20, true),
  ('Sol Plaatje University', 'SPU', 'Northern Cape', 'university', 'https://www.spu.ac.za', 22, true),
  ('University of Mpumalanga', 'UMP', 'Mpumalanga', 'university', 'https://www.ump.ac.za', 22, true),
  ('Sefako Makgatho Health Sciences University', 'SMU', 'Gauteng', 'university', 'https://www.smu.ac.za', 28, false),
  ('UNISA', 'UNISA', 'Gauteng', 'comprehensive', 'https://www.unisa.ac.za', 18, true)
on conflict do nothing;

-- ============================================================
-- SEED DATA: TVET Colleges (selection)
-- ============================================================
insert into tvet_colleges (name, province, website, nated_programmes, nc_v_programmes) values
  ('Ekurhuleni East TVET College', 'Gauteng', 'https://www.eec.edu.za', true, true),
  ('Ekurhuleni West TVET College', 'Gauteng', 'https://www.ewc.edu.za', true, true),
  ('South West Gauteng TVET College', 'Gauteng', 'https://www.swgc.co.za', true, true),
  ('Tshwane North TVET College', 'Gauteng', 'https://www.tnc.edu.za', true, true),
  ('Tshwane South TVET College', 'Gauteng', 'https://www.tsc.edu.za', true, true),
  ('College of Cape Town', 'Western Cape', 'https://www.cct.edu.za', true, true),
  ('False Bay TVET College', 'Western Cape', 'https://www.falsebaycollege.co.za', true, true),
  ('Northlink TVET College', 'Western Cape', 'https://www.northlink.co.za', true, true),
  ('Coastal KZN TVET College', 'KwaZulu-Natal', 'https://www.coastalkzn.co.za', true, true),
  ('Majuba TVET College', 'KwaZulu-Natal', 'https://www.majuba.edu.za', true, true),
  ('Motheo TVET College', 'Free State', 'https://www.motheotvet.co.za', true, true),
  ('Nkangala TVET College', 'Mpumalanga', 'https://www.nkangalacollege.edu.za', true, true),
  ('Lephalale TVET College', 'Limpopo', 'https://www.leptvet.edu.za', true, true),
  ('Orbit TVET College', 'North West', 'https://www.orbitcollege.co.za', true, true),
  ('Buffalo City TVET College', 'Eastern Cape', 'https://www.bfrec.co.za', true, true)
on conflict do nothing;

-- ============================================================
-- INDEXES
-- ============================================================
create index if not exists idx_programmes_institution on programmes(institution_id);
create index if not exists idx_programmes_tvet on programmes(tvet_college_id);
create index if not exists idx_programmes_field on programmes(field_of_study);
create index if not exists idx_careers_sector on careers(sector);
create index if not exists idx_bursaries_category on bursaries(category);
create index if not exists idx_bursaries_active on bursaries(is_active);
