-- Run in Supabase SQL editor

create table if not exists public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  gender_index integer not null default -1,
  goal_index integer not null default -1,
  age_years integer not null default 21,
  weight_kg integer not null default 66,
  is_weight_in_kg boolean not null default true,
  height_cm integer not null default 160,
  is_height_in_cm boolean not null default true,
  activity_index integer not null default -1,
  diet_preference_index integer not null default -1,
  country_name text not null default '',
  budget_enabled boolean not null default true,
  budget_currency_code text not null default 'INR',
  budget_per_meal integer,
  custom_budget_per_meal text not null default '',
  is_custom_budget_per_meal boolean not null default false,
  hydration_enabled boolean not null default true,
  hydration_goal_text text not null default '',
  is_hydration_in_liters boolean not null default true,
  skipped_budget_section boolean not null default false,
  skipped_water_section boolean not null default false,
  nutrition_goal_values jsonb not null default '{}'::jsonb,
  advanced_nutrition_goal_values jsonb not null default '{}'::jsonb,
  profile_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_user_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_user_profiles_updated_at on public.user_profiles;
create trigger trg_user_profiles_updated_at
before update on public.user_profiles
for each row
execute function public.set_user_profiles_updated_at();

alter table public.user_profiles enable row level security;

drop policy if exists "user_profiles_select_own" on public.user_profiles;
create policy "user_profiles_select_own"
on public.user_profiles
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "user_profiles_insert_own" on public.user_profiles;
create policy "user_profiles_insert_own"
on public.user_profiles
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "user_profiles_update_own" on public.user_profiles;
create policy "user_profiles_update_own"
on public.user_profiles
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "user_profiles_delete_own" on public.user_profiles;
create policy "user_profiles_delete_own"
on public.user_profiles
for delete
to authenticated
using (auth.uid() = user_id);
