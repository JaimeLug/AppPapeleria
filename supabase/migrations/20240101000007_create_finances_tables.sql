-- Incomes table schema
create table if not exists public.incomes (
  id uuid default gen_random_uuid() primary key,
  amount numeric(10,2) not null,
  date timestamp with time zone not null,
  category text not null,
  description text,
  payment_method text not null,
  order_id uuid references public.orders(id) on delete set null, -- Optional link to order
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users(id)
);

-- Expenses table schema
create table if not exists public.expenses (
  id uuid default gen_random_uuid() primary key,
  amount numeric(10,2) not null,
  date timestamp with time zone not null,
  category text not null,
  description text,
  payment_method text not null,
  receipt_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users(id)
);

-- RLS
alter table public.incomes enable row level security;
alter table public.expenses enable row level security;

-- Incomes Policies
create policy "Users can view their own incomes"
  on public.incomes for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own incomes"
  on public.incomes for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own incomes"
  on public.incomes for update
  using ( auth.uid() = user_id );

create policy "Users can delete their own incomes"
  on public.incomes for delete
  using ( auth.uid() = user_id );

-- Expenses Policies
create policy "Users can view their own expenses"
  on public.expenses for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own expenses"
  on public.expenses for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own expenses"
  on public.expenses for update
  using ( auth.uid() = user_id );

create policy "Users can delete their own expenses"
  on public.expenses for delete
  using ( auth.uid() = user_id );
