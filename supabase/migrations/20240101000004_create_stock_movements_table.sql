-- Stock movements table schema
create table if not exists public.stock_movements (
  id uuid default gen_random_uuid() primary key,
  inventory_item_id uuid references public.inventory_items(id) on delete cascade not null,
  type text not null check (type in ('entrada', 'salida', 'ajuste')),
  quantity integer not null,
  previous_quantity integer not null,
  new_quantity integer not null,
  reason text,
  date timestamp with time zone default timezone('utc'::text, now()) not null,
  is_deleted boolean default false not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users(id)
);

-- RLS
alter table public.stock_movements enable row level security;

create policy "Users can view their own stock movements"
  on public.stock_movements for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own stock movements"
  on public.stock_movements for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own stock movements"
  on public.stock_movements for update
  using ( auth.uid() = user_id );

create policy "Users can delete their own stock movements"
  on public.stock_movements for delete
  using ( auth.uid() = user_id );
