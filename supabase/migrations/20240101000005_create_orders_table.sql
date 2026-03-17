-- Orders table schema
create table if not exists public.orders (
  id uuid default gen_random_uuid() primary key,
  customer_id uuid references public.customers(id) on delete set null,
  order_date timestamp with time zone not null,
  delivery_date timestamp with time zone not null,
  delivery_status text not null check (delivery_status in ('pending', 'delivered', 'cancelled')),
  payment_status text not null check (payment_status in ('pending', 'partial', 'paid')),
  total_amount numeric(10,2) not null default 0,
  advance_payment numeric(10,2) not null default 0,
  delivery_type text not null check (delivery_type in ('pickup', 'shipping')),
  shipping_address text,
  shipping_cost numeric(10,2) not null default 0,
  is_urgent boolean not null default false,
  notes text,
  google_calendar_event_id text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users(id)
);

-- RLS
alter table public.orders enable row level security;

create policy "Users can view their own orders"
  on public.orders for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own orders"
  on public.orders for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own orders"
  on public.orders for update
  using ( auth.uid() = user_id );

create policy "Users can delete their own orders"
  on public.orders for delete
  using ( auth.uid() = user_id );
