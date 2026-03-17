-- Inventory items table schema
create table if not exists public.inventory_items (
  id uuid default gen_random_uuid() primary key,
  product_id uuid references public.products(id) on delete cascade not null,
  name text not null,
  quantity integer not null default 0,
  min_quantity integer not null default 5,
  location text not null default 'Tienda',
  category text not null,
  is_deleted boolean default false not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users(id)
);

-- RLS
alter table public.inventory_items enable row level security;

create policy "Users can view their own inventory items"
  on public.inventory_items for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own inventory items"
  on public.inventory_items for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own inventory items"
  on public.inventory_items for update
  using ( auth.uid() = user_id );

create policy "Users can delete their own inventory items"
  on public.inventory_items for delete
  using ( auth.uid() = user_id );
