-- Products table schema
create table if not exists public.products (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  base_price numeric(10,2) not null,
  extra_cost numeric(10,2) not null default 0,
  category text not null,
  notes text,
  is_deleted boolean default false not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users(id)
);

-- RLS
alter table public.products enable row level security;

create policy "Users can view their own products"
  on public.products for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own products"
  on public.products for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own products"
  on public.products for update
  using ( auth.uid() = user_id );

create policy "Users can delete their own products"
  on public.products for delete
  using ( auth.uid() = user_id );
