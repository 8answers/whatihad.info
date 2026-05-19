-- Run in Supabase SQL editor
--
-- Enables authenticated users to delete their own auth account by calling:
--   select public.delete_current_user();
--
-- App-side call:
--   supabase.rpc('delete_current_user');

create or replace function public.delete_current_user()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Not authenticated'
      using errcode = '42501';
  end if;

  delete from auth.users
  where id = current_user_id;
end;
$$;

revoke all on function public.delete_current_user() from public;
grant execute on function public.delete_current_user() to authenticated;
