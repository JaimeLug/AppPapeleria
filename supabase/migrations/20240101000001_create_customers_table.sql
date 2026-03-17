-- Customer table schema
create table if not exists public.customers (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  phone text,
  is_deleted boolean default false not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  -- Foreign key to auth.users if needed for multi-tenant (or simple RLS)
  user_id uuid references auth.users(id)
);

-- RLS
alter table public.customers enable row level security;

-- Policies (Assuming multi-tenant, only user can see their customers)
create policy "Users can view their own customers"
  on public.customers for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own customers"
  on public.customers for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own customers"
  on public.customers for update
  using ( auth.uid() = user_id );

create policy "Users can delete their own customers"
  on public.customers for delete
  using ( auth.uid() = user_id );
