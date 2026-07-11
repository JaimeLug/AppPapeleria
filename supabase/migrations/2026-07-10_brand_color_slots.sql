-- ============================================================================
-- Migración: slots de color configurables para el rediseño 2026.
-- ----------------------------------------------------------------------------
-- Agrega a brand_settings los colores editables desde "Colores de la App":
--   * sidebar_color_hex            — menú lateral
--   * dash_receivable_color_hex    — tarjeta "Por Cobrar"
--   * dash_income_color_hex        — ingresos / utilidad positiva
--   * dash_expense_color_hex       — gastos
--   * dash_neutral_color_hex       — entregas sin urgencia / neutro
--   * dash_negative_color_hex      — pérdida / urgente
-- Todos nullable: NULL = usar el color por defecto del tema. Enteros ARGB
-- (0xFF......) que exceden int32 -> bigint, igual que los colores existentes.
--
-- Idempotente y sin tocar datos. Aplicar en: Dashboard > SQL Editor > Run.
-- ============================================================================

alter table public.brand_settings add column if not exists sidebar_color_hex bigint;
alter table public.brand_settings add column if not exists dash_receivable_color_hex bigint;
alter table public.brand_settings add column if not exists dash_income_color_hex bigint;
alter table public.brand_settings add column if not exists dash_expense_color_hex bigint;
alter table public.brand_settings add column if not exists dash_neutral_color_hex bigint;
alter table public.brand_settings add column if not exists dash_negative_color_hex bigint;
