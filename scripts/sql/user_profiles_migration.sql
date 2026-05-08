-- Run this when public.user_profiles already exists with older columns.
-- Safe to run multiple times.

-- Drop any legacy RLS policies first (some old policy expressions can break
-- type-alter operations with errors like "text >= numeric").
do $$
declare
  policy_row record;
begin
  for policy_row in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_profiles'
  loop
    execute format(
      'drop policy if exists %I on public.user_profiles',
      policy_row.policyname
    );
  end loop;
end
$$;

-- Drop legacy CHECK constraints so type migration can proceed cleanly.
do $$
declare
  constraint_row record;
begin
  for constraint_row in
    select c.conname
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'user_profiles'
      and c.contype = 'c'
  loop
    execute format(
      'alter table public.user_profiles drop constraint if exists %I',
      constraint_row.conname
    );
  end loop;
end
$$;

alter table public.user_profiles
  add column if not exists name text not null default '',
  add column if not exists gender_index integer not null default -1,
  add column if not exists goal_index integer not null default -1,
  add column if not exists age_years integer not null default 21,
  add column if not exists weight_kg integer not null default 66,
  add column if not exists is_weight_in_kg boolean not null default true,
  add column if not exists height_cm integer not null default 160,
  add column if not exists is_height_in_cm boolean not null default true,
  add column if not exists activity_index integer not null default -1,
  add column if not exists diet_preference_index integer not null default -1,
  add column if not exists country_name text not null default '',
  add column if not exists budget_enabled boolean not null default true,
  add column if not exists budget_currency_code text not null default 'INR',
  add column if not exists budget_per_meal integer,
  add column if not exists custom_budget_per_meal text not null default '',
  add column if not exists is_custom_budget_per_meal boolean not null default false,
  add column if not exists hydration_enabled boolean not null default true,
  add column if not exists hydration_goal_text text not null default '',
  add column if not exists is_hydration_in_liters boolean not null default true,
  add column if not exists skipped_budget_section boolean not null default false,
  add column if not exists skipped_water_section boolean not null default false,
  add column if not exists nutrition_goal_values jsonb not null default '{}'::jsonb,
  add column if not exists advanced_nutrition_goal_values jsonb not null default '{}'::jsonb,
  add column if not exists profile_json jsonb not null default '{}'::jsonb,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

-- Normalize key column types for older incompatible schemas.
alter table public.user_profiles
  alter column name type text using coalesce(name::text, ''),
  alter column country_name type text using coalesce(country_name::text, ''),
  alter column budget_currency_code type text using coalesce(budget_currency_code::text, 'INR'),
  alter column custom_budget_per_meal type text using coalesce(custom_budget_per_meal::text, '0'),
  alter column hydration_goal_text type text using coalesce(hydration_goal_text::text, '');

-- If an old selected_budget_per_meal column exists, move values into
-- budget_per_meal before dropping selected_* columns.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_profiles'
      and column_name = 'selected_budget_per_meal'
  ) then
    execute $sql$
      update public.user_profiles
      set budget_per_meal = coalesce(
        budget_per_meal,
        nullif(trim(selected_budget_per_meal::text), '')::integer
      )
      where budget_per_meal is null
    $sql$;
  end if;
end
$$;

-- Drop all selected_* columns (user requested).
do $$
declare
  selected_col record;
begin
  for selected_col in
    select column_name
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_profiles'
      and column_name like 'selected\_%' escape '\'
  loop
    execute format(
      'alter table public.user_profiles drop column if exists %I',
      selected_col.column_name
    );
  end loop;
end
$$;

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
