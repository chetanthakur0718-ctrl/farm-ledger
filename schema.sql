-- Farm Ledger: database setup for Supabase.
-- Paste this whole file into Supabase > SQL Editor > New query, then press Run.
-- It is safe to run once on a new, empty project.

-- 1) People who can log in. The first account ever created becomes the owner.
--    Every later account starts as "pending" until the owner approves it in the app.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role text not null default 'pending' check (role in ('owner','staff','pending')),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, role)
  values (
    new.id,
    new.email,
    case when (select count(*) from public.profiles) = 0 then 'owner' else 'pending' end
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Helper: role of the person who is logged in right now.
create or replace function public.my_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

-- 2) Settings of the app (sheet names, columns, defaults). One row.
create table if not exists public.config (
  id text primary key default 'main',
  data jsonb not null,
  updated_at timestamptz not null default now()
);

-- 3) All entries of all sheets (farmers, labour, digging, storage, ...).
create table if not exists public.rows (
  tbl text not null,
  id text not null,
  data jsonb not null,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (tbl, id)
);

-- 4) Who may do what.
alter table public.profiles enable row level security;
alter table public.config   enable row level security;
alter table public.rows     enable row level security;

-- profiles: everybody sees their own line; the owner sees everybody and can approve staff.
drop policy if exists "profiles read own" on public.profiles;
create policy "profiles read own" on public.profiles
  for select to authenticated using (id = auth.uid());

drop policy if exists "profiles read all for owner" on public.profiles;
create policy "profiles read all for owner" on public.profiles
  for select to authenticated using (public.my_role() = 'owner');

drop policy if exists "profiles update by owner" on public.profiles;
create policy "profiles update by owner" on public.profiles
  for update to authenticated
  using (public.my_role() = 'owner')
  with check (public.my_role() = 'owner');

-- config: owner and staff can read; only the owner can change.
drop policy if exists "config read" on public.config;
create policy "config read" on public.config
  for select to authenticated using (public.my_role() in ('owner','staff'));

drop policy if exists "config insert owner" on public.config;
create policy "config insert owner" on public.config
  for insert to authenticated with check (public.my_role() = 'owner');

drop policy if exists "config update owner" on public.config;
create policy "config update owner" on public.config
  for update to authenticated
  using (public.my_role() = 'owner')
  with check (public.my_role() = 'owner');

-- rows: owner and staff can read, add and edit; only the owner can delete.
drop policy if exists "rows read" on public.rows;
create policy "rows read" on public.rows
  for select to authenticated using (public.my_role() in ('owner','staff'));

drop policy if exists "rows insert" on public.rows;
create policy "rows insert" on public.rows
  for insert to authenticated with check (public.my_role() in ('owner','staff'));

drop policy if exists "rows update" on public.rows;
create policy "rows update" on public.rows
  for update to authenticated
  using (public.my_role() in ('owner','staff'))
  with check (public.my_role() in ('owner','staff'));

drop policy if exists "rows delete owner" on public.rows;
create policy "rows delete owner" on public.rows
  for delete to authenticated using (public.my_role() = 'owner');

-- 5) Live updates: changes made by one person appear on other people's screens.
do $$
begin
  begin
    alter publication supabase_realtime add table public.rows;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.config;
  exception when duplicate_object then null;
  end;
end;
$$;