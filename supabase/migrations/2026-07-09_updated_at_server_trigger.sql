-- ============================================================================
-- Migración: updated_at autoritativo por reloj del SERVIDOR (LWW por hora de
-- llegada, no por el reloj del cliente).
-- ----------------------------------------------------------------------------
-- Problema que resuelve (#2 de la auditoría):
--   La app escribe `updated_at = DateTime.now()` con el reloj de CADA
--   computadora. La reconciliación local compara ese sello
--   (remote.updatedAt.isAfter(local.updatedAt)); si un equipo tiene el reloj
--   adelantado, "gana" siempre aunque haya editado antes en tiempo real.
--
-- Qué hace:
--   Un trigger BEFORE INSERT OR UPDATE fija `updated_at = now()` en el servidor,
--   ignorando el valor que mande el cliente. Así el orden de última escritura
--   lo decide el servidor por hora de llegada (con ambos equipos en línea,
--   llegada ≈ momento real de la edición).
--
-- Seguridad: NO borra ni modifica datos existentes. Solo afecta al valor de
--   updated_at en la PRÓXIMA escritura de cada fila. Idempotente: se puede
--   volver a correr sin romper nada.
--
-- Cómo aplicar: Supabase Dashboard > SQL Editor > New query > pega y ejecuta.
-- Hazlo una sola vez (afecta a las 2 computadoras porque comparten el proyecto).
-- ============================================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

do $$
declare
  t text;
begin
  -- Solo las tablas que tienen columna updated_at.
  -- (order_items y stock_movements son append-only y no la tienen.)
  foreach t in array array[
    'brand_settings','products','inventory_items','customers','orders','expenses','incomes'
  ]
  loop
    execute format('drop trigger if exists trg_set_updated_at on public.%I;', t);
    execute format(
      'create trigger trg_set_updated_at
         before insert or update on public.%I
         for each row execute function public.set_updated_at();', t);
  end loop;
end $$;
