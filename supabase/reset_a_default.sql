-- ============================================================================
-- RESET A DEFAULT — deja el proyecto Supabase LIMPIO para entregar a la clienta
-- ----------------------------------------------------------------------------
-- ⚠️ DESTRUCTIVO: borra TODOS los datos del negocio (pedidos, clientes,
--    productos, inventario, movimientos, gastos, ingresos) y quita el logo y
--    los colores personalizados, dejando la marca por defecto "Papelería Pro".
--
-- Úsalo SOLO para dejar la app en estado de fábrica antes de entregarla.
-- NO tiene deshacer. Confirmado: los datos actuales son de prueba.
--
-- Cómo correr: Supabase Dashboard > SQL Editor > New query > pega TODO > Run.
-- ============================================================================

-- 0) Asegura que existan las columnas de color del rediseño (por si no se
--    corrió la migración 2026-07-10_brand_color_slots.sql). Idempotente.
alter table public.brand_settings add column if not exists sidebar_color_hex bigint;
alter table public.brand_settings add column if not exists dash_receivable_color_hex bigint;
alter table public.brand_settings add column if not exists dash_income_color_hex bigint;
alter table public.brand_settings add column if not exists dash_expense_color_hex bigint;
alter table public.brand_settings add column if not exists dash_neutral_color_hex bigint;
alter table public.brand_settings add column if not exists dash_negative_color_hex bigint;

-- 1) Vaciar todos los datos del negocio.
--    order_items y stock_movements caen por ON DELETE CASCADE, pero los
--    truncamos explícito por si acaso. RESTART IDENTITY reinicia secuencias.
truncate table
  public.order_items,
  public.stock_movements,
  public.orders,
  public.products,
  public.inventory_items,
  public.customers,
  public.expenses,
  public.incomes
restart identity cascade;

-- 2) Resetear la marca a los valores por defecto del rediseño:
--    sin logo, colores terracota/verde, sin overrides de fondo/tarjetas/sidebar
--    ni colores de tarjetas del dashboard.
update public.brand_settings set
  app_name                  = 'Papelería Pro',
  logo_base64               = null,
  primary_color_hex         = 4291057439, -- 0xFFC4571F terracota
  accent_color_hex          = 4280187469, -- 0xFF1E7A4D verde
  background_color_hex      = null,
  surface_color_hex         = null,
  sidebar_color_hex         = null,
  dash_receivable_color_hex = null,
  dash_income_color_hex     = null,
  dash_expense_color_hex    = null,
  dash_neutral_color_hex    = null,
  dash_negative_color_hex   = null,
  updated_at                = now()
where id = 1;

-- Si por alguna razón no existiera la fila de marca, la creamos.
insert into public.brand_settings (id, app_name, primary_color_hex, accent_color_hex, updated_at)
values (1, 'Papelería Pro', 4291057439, 4280187469, now())
on conflict (id) do nothing;

-- ============================================================================
-- LISTO. Después de correr esto:
--  1) En TU computadora: abre la app > Configuración > Herramientas del
--     Desarrollador > "Resetear Base de Datos (Fábrica)" (PIN 2308) para
--     limpiar el caché local. (Si no, tu equipo seguirá mostrando lo viejo.)
--  2) La clienta instala la app nueva > entra > verá todo vacío y la marca
--     por defecto. Ella sube su logo y elige sus colores en Ajustes.
-- ============================================================================
