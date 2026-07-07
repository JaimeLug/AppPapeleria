-- ============================================================================
-- Papelería Pro — Esquema completo de Supabase
-- ----------------------------------------------------------------------------
-- Reconstruido a partir de los repositorios de la app (lib/features/**/data).
-- Ejecuta este archivo COMPLETO en:  Supabase Dashboard > SQL Editor > New query
-- Es idempotente: se puede volver a correr sin romper nada.
--
-- Convenciones de la app:
--  * Los IDs los genera la app (UUID v4 como texto). Por eso las PK son `text`.
--    Las tablas cuyo id NO envía la app (order_items, stock_movements) llevan
--    un default para autogenerarlo.
--  * Borrado lógico: casi todas las tablas usan `is_deleted boolean`.
--  * Los colores de marca se guardan como entero ARGB (0xFF...), que supera el
--    rango de int32 -> se usa `bigint`.
--  * Multi-tenant: NO. Es un negocio único. RLS abierto a usuarios autenticados.
-- ============================================================================

-- ------------------------------------------------------------------
-- 1. brand_settings  (marca blanca — fila única id = 1)
-- ------------------------------------------------------------------
create table if not exists public.brand_settings (
  id                integer primary key,
  app_name          text        not null default 'Papelería Pro',
  primary_color_hex bigint      not null default 4287349434, -- 0xFF8E24AA
  accent_color_hex  bigint      not null default 4290083016, -- 0xFFBA68C8
  logo_base64          text,                                 -- logo del negocio (base64)
  background_color_hex bigint,                                -- fondo (modo claro)
  surface_color_hex    bigint,                                -- tarjetas (modo claro)
  updated_at        timestamptz not null default now()
);
-- Para bases ya creadas sin estas columnas:
alter table public.brand_settings add column if not exists logo_base64 text;
alter table public.brand_settings add column if not exists background_color_hex bigint;
alter table public.brand_settings add column if not exists surface_color_hex bigint;

-- ------------------------------------------------------------------
-- 2. products  (catálogo de venta)
-- ------------------------------------------------------------------
create table if not exists public.products (
  id          text primary key,
  name        text not null,
  base_price  numeric not null default 0,
  extra_cost  numeric not null default 0,
  category    text,
  notes       text,
  is_deleted  boolean not null default false,
  updated_at  timestamptz not null default now()
);

-- ------------------------------------------------------------------
-- 3. inventory_items  (materia prima / stock)
-- ------------------------------------------------------------------
create table if not exists public.inventory_items (
  id              text primary key,
  name            text not null,
  sku             text,
  item_type       text not null default 'Materia Prima',
  unit_of_measure text not null default 'Piezas',
  current_stock   numeric not null default 0,
  minimum_stock   numeric not null default 0,
  unit_cost       numeric not null default 0,
  is_deleted      boolean not null default false,
  updated_at      timestamptz not null default now()
);

-- ------------------------------------------------------------------
-- 4. stock_movements  (entradas/salidas/mermas)
--    id opcional en la app -> default autogenerado
-- ------------------------------------------------------------------
create table if not exists public.stock_movements (
  id              text primary key default gen_random_uuid()::text,
  item_id         text references public.inventory_items(id) on delete cascade,
  movement_type   text not null,          -- 'Entrada' | 'Salida' | 'Mermas/Dañado'
  quantity        numeric not null default 0,
  reason          text,
  date            timestamptz not null default now(),
  is_item_deleted boolean not null default false
);
create index if not exists idx_stock_movements_item_id on public.stock_movements(item_id);

-- ------------------------------------------------------------------
-- 5. customers
-- ------------------------------------------------------------------
create table if not exists public.customers (
  id          text primary key,
  name        text not null,
  phone       text,
  is_deleted  boolean not null default false,
  updated_at  timestamptz not null default now()
);

-- ------------------------------------------------------------------
-- 6. orders  (pedidos)
-- ------------------------------------------------------------------
create table if not exists public.orders (
  id               text primary key,
  customer_name    text,
  total_price      numeric not null default 0,
  pending_balance  numeric not null default 0,
  delivery_date    timestamptz not null,
  sale_date        timestamptz not null default now(),
  payment_status   text not null default 'pending',
  delivery_status  text not null default 'pending',
  google_event_id  text,   -- legado; se conserva por compatibilidad del modelo
  notes            text,
  is_deleted       boolean not null default false,
  updated_at       timestamptz not null default now()
);
create index if not exists idx_orders_sale_date on public.orders(sale_date desc);

-- ------------------------------------------------------------------
-- 7. order_items  (renglones de cada pedido — id autogenerado)
-- ------------------------------------------------------------------
create table if not exists public.order_items (
  id           text primary key default gen_random_uuid()::text,
  order_id     text references public.orders(id) on delete cascade,
  product_id   text,
  product_name text,
  price        numeric not null default 0,
  quantity     integer not null default 1,
  notes        text
);
create index if not exists idx_order_items_order_id on public.order_items(order_id);

-- ------------------------------------------------------------------
-- 8. expenses  (gastos)
-- ------------------------------------------------------------------
create table if not exists public.expenses (
  id          text primary key,
  description text,
  amount      numeric not null default 0,
  date        timestamptz not null default now(),
  category    text not null default 'Otros',
  is_deleted  boolean not null default false,
  updated_at  timestamptz not null default now()
);
create index if not exists idx_expenses_date on public.expenses(date desc);

-- ------------------------------------------------------------------
-- 9. incomes  (ingresos)
-- ------------------------------------------------------------------
create table if not exists public.incomes (
  id          text primary key,
  description text,
  amount      numeric not null default 0,
  date        timestamptz not null default now(),
  category    text not null default 'General',
  is_deleted  boolean not null default false,
  updated_at  timestamptz not null default now()
);
create index if not exists idx_incomes_date on public.incomes(date desc);


-- ============================================================================
-- ROW LEVEL SECURITY
-- ----------------------------------------------------------------------------
-- Negocio único: cualquier usuario autenticado tiene acceso total.
-- (Si en el futuro quieres multi-negocio, aquí se filtraría por auth.uid()).
-- ============================================================================
do $$
declare
  t text;
begin
  foreach t in array array[
    'brand_settings','products','inventory_items','stock_movements',
    'customers','orders','order_items','expenses','incomes'
  ]
  loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists "authenticated_all" on public.%I;', t);
    execute format(
      'create policy "authenticated_all" on public.%I
         for all to authenticated using (true) with check (true);', t);
  end loop;
end $$;


-- ============================================================================
-- REALTIME
-- ----------------------------------------------------------------------------
-- La app escucha cambios en vivo (.stream()) de estas tablas.
-- ============================================================================
do $$
begin
  begin execute 'alter publication supabase_realtime add table public.products';  exception when duplicate_object then null; end;
  begin execute 'alter publication supabase_realtime add table public.customers'; exception when duplicate_object then null; end;
  begin execute 'alter publication supabase_realtime add table public.orders';    exception when duplicate_object then null; end;
end $$;


-- ============================================================================
-- SEED — fila única de marca blanca
-- ============================================================================
insert into public.brand_settings (id, app_name, primary_color_hex, accent_color_hex, updated_at)
values (1, 'Papelería Pro', 4287349434, 4290083016, now())
on conflict (id) do nothing;

-- ============================================================================
-- LISTO. Después de correr esto:
--  1) Authentication > Users > Add user  (crea tu usuario email+contraseña).
--     Marca "Auto Confirm User" para poder entrar sin verificar el correo.
--  2) Copia Project URL y anon key a tu archivo .env (ver .env.example).
-- ============================================================================
