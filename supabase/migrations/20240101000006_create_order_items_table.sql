-- Order items table schema
create table if not exists public.order_items (
  id uuid default gen_random_uuid() primary key,
  order_id uuid references public.orders(id) on delete cascade not null,
  product_id uuid references public.products(id) on delete set null,
  quantity integer not null,
  unit_price numeric(10,2) not null,
  notes text,
  is_deleted boolean default false not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users(id)
);

-- RLS
alter table public.order_items enable row level security;

create policy "Users can view their own order items"
  on public.order_items for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own order items"
  on public.order_items for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own order items"
  on public.order_items for update
  using ( auth.uid() = user_id );

create policy "Users can delete their own order items"
  on public.order_items for delete
  using ( auth.uid() = user_id );
