-- Khetha Go Database Schema
-- Run this in Supabase SQL Editor after creating your project

-- Learning Providers (Universities, UoTs, TVET Colleges)
create table if not exists learning_providers (
  id text primary key,
  name text not null,
  abbreviation text,
  province text not null,
  town text not null,
  type text not null,
  description text,
  total_students int,
  email text,
  phone text,
  website text,
  nsfas_accredited boolean default true,
  offered_fields text[] default '{}',
  image_url text,
  logo_url text,
  hero_image_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Careers / Occupations
create table if not exists careers (
  id text primary key,
  title text not null,
  ofo_code text,
  description text not null,
  day_in_the_life text,
  sector text not null,
  required_subjects text[] default '{}',
  helpful_subjects text[] default '{}',
  traits text[] default '{}',
  riasec jsonb default '{}',
  study_pathway text,
  min_qualification text,
  nqf_level text,
  entry_salary_band text,
  experienced_salary_band text,
  demand text default 'stable',
  scarce_skill boolean default false,
  related_career_ids text[] default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Qualifications / Programmes
create table if not exists qualifications (
  id text primary key,
  title text not null,
  saqa_id text,
  field text not null,
  nqf_level text,
  duration text,
  provider_type text,
  minimum_requirements text,
  aps_required int default 0,
  pass_required text default 'diploma',
  requirements jsonb default '[]',
  leads_to_career_ids text[] default '{}',
  articulates_to text[] default '{}',
  is_extended_programme boolean default false,
  offered_by text[] default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Bursaries (for future use)
create table if not exists bursaries (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  provider text,
  field_of_study text,
  amount text,
  closing_date date,
  requirements text,
  url text,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- Support resources
create table if not exists support_resources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  kind text not null,
  value text not null,
  availability text,
  free_to_use boolean default false,
  created_at timestamptz default now()
);

-- Auto-update the updated_at timestamp
create or replace function update_modified_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger learning_providers_updated before update on learning_providers
  for each row execute function update_modified_column();

create trigger careers_updated before update on careers
  for each row execute function update_modified_column();

create trigger qualifications_updated before update on qualifications
  for each row execute function update_modified_column();

-- Row Level Security (public read, authenticated write)
alter table learning_providers enable row level security;
alter table careers enable row level security;
alter table qualifications enable row level security;
alter table bursaries enable row level security;
alter table support_resources enable row level security;

create policy "Public read access" on learning_providers for select using (true);
create policy "Public read access" on careers for select using (true);
create policy "Public read access" on qualifications for select using (true);
create policy "Public read access" on bursaries for select using (true);
create policy "Public read access" on support_resources for select using (true);

-- Storage bucket for university images
-- Run this separately in SQL editor or via Dashboard > Storage
insert into storage.buckets (id, name, public)
values ('university-images', 'university-images', true)
on conflict (id) do nothing;

create policy "Public read images" on storage.objects
  for select using (bucket_id = 'university-images');

create policy "Auth upload images" on storage.objects
  for insert with check (bucket_id = 'university-images');

create policy "Auth update images" on storage.objects
  for update using (bucket_id = 'university-images');
