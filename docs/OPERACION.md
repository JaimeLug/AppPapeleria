# Operación y mantenimiento

Guía técnica para operar Papelería Pro (reset, respaldos, base de datos y
problemas comunes).

## Arquitectura en 30 segundos
- **Flutter (Windows desktop)**, estado con **Riverpod**.
- **Offline-first**: los datos viven en **Hive** (local) y se sincronizan con
  **Supabase** (nube). Los repos `offline_first_*` envuelven a los
  `supabase_*` y el `SyncManager` empuja lo pendiente.
- **Realtime**: cambios en la nube (otra computadora) se reflejan en vivo.
- **Marca blanca**: nombre, logo y colores se guardan en `brand_settings` y se
  comparten entre las computadoras del mismo proyecto Supabase.
- **Credenciales**: la app usa las credenciales guardadas en el asistente y,
  si no hay, el `.env` empaquetado (ver [GUIA_ALTA_CLIENTE](GUIA_ALTA_CLIENTE.md)).

## Scripts SQL (carpeta `supabase/`)
Se corren en **Supabase Dashboard → SQL Editor → New query → Run**.
- **`schema.sql`** — esquema completo (tablas, RLS, Realtime, trigger de
  `updated_at`, columnas de color de marca). Idempotente. Base para un
  proyecto nuevo.
- **`migrations/2026-07-09_updated_at_server_trigger.sql`** — hace que el
  `updated_at` lo ponga el servidor (evita conflictos por relojes desfasados).
- **`migrations/2026-07-10_brand_color_slots.sql`** — columnas de color del
  rediseño (sidebar + tarjetas del dashboard).
- **`reset_a_default.sql`** — ⚠️ DESTRUCTIVO. Vacía todos los datos y deja la
  marca por defecto (sin logo). Para dejar la app lista para entregar.

> `schema.sql` ya incluye lo de las dos migraciones; sirven para bases que se
> crearon antes de esos cambios.

## Dejar la app "de fábrica" (antes de entregar)
1. Corre `supabase/reset_a_default.sql` en Supabase (borra datos + marca).
2. En la computadora: **Ajustes → Herramientas del Desarrollador →
   "Resetear Base de Datos (Fábrica)"** (PIN `2308`). Limpia el caché local
   (datos + marca).
3. Al reabrir, sale el **asistente de bienvenida** (porque es "primera vez").

## Herramientas del Desarrollador (Ajustes)
- **Exportar / Importar Backup**: respaldo completo en un archivo `.json`
  (clientes, pedidos, productos, inventario, movimientos, gastos, ingresos y
  ajustes; el PIN de finanzas NO se incluye). El import es compatible con
  respaldos viejos.
- **Resetear Base de Datos (Fábrica)** (PIN `2308`): borra los datos y la
  marca **locales**. Es local: si la nube tiene datos, se vuelven a bajar; para
  un reset total usa además `reset_a_default.sql`.

## PIN de finanzas
- Protege el acceso a Finanzas. Se guarda local (Hive) y NO viaja en el backup.
- Para cambiarlo hay que ingresar el PIN actual.

## Problemas comunes
- **`LNK1168` al compilar** ("no se puede abrir app_papeleria.exe"): la app
  está abierta. Ciérrala (o mata el proceso `app_papeleria`) y recompila.
- **"Conecta tu base de datos" al abrir**: no hay credenciales (ni `.env` ni
  guardadas). Ingresa Project URL + anon key y reinicia.
- **No sincroniza**: revisa que haya sesión iniciada y conexión. La sync no
  corre sin sesión (por diseño, para no dejar registros colgados).
- **Cambié de base y sigue mostrando lo viejo**: reinicia la app (las
  credenciales nuevas se aplican al arrancar) y/o haz Factory Reset local.

## Compilar / correr
```
flutter pub get
flutter run -d windows              # desarrollo
flutter build windows --release     # build para el instalador
flutter test                        # pruebas
flutter analyze                     # análisis estático
```
Ver el instalador en [GUIA_ALTA_CLIENTE](GUIA_ALTA_CLIENTE.md).
