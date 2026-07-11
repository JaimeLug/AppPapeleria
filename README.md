# Papelería Pro

Punto de venta (POS) de escritorio para papelerías, **marca blanca** y
**offline-first**. Hecho en Flutter (Windows), con Hive local + Supabase en la
nube y sincronización en tiempo real entre dispositivos.

## Funciones
- **Ventas y pedidos**: catálogo, carrito, anticipos, estados de entrega,
  tickets en PDF.
- **Inventario**: materia prima, stock y movimientos.
- **Clientes** y **finanzas** (ingresos/gastos, utilidad, por mes).
- **Dashboard personalizable** (mover, redimensionar, agregar/quitar tarjetas).
- **Marca blanca**: nombre, logo y paleta de colores totalmente configurables
  (menú *Colores de la App*), compartidos entre las computadoras del negocio.
- **Asistente de bienvenida** en la primera apertura (conexión, cuenta y marca).
- **Multi-cliente**: cada cliente puede conectar su propia base de datos.

## Documentación
- **[docs/GUIA_ALTA_CLIENTE.md](docs/GUIA_ALTA_CLIENTE.md)** — dar de alta un
  cliente nuevo (crear su base, cuenta y compilar el instalador).
- **[docs/OPERACION.md](docs/OPERACION.md)** — reset a default, herramientas de
  desarrollador, scripts SQL y problemas comunes.

## Arranque rápido (desarrollo)
```
flutter pub get
flutter run -d windows
```
Necesitas un archivo `.env` en la raíz (ver `.env.example`) con las
credenciales de Supabase:
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...
```
El esquema de la base está en [`supabase/schema.sql`](supabase/schema.sql).

## Comandos útiles
```
flutter build windows --release     # build para el instalador
flutter test                        # pruebas
flutter analyze                     # análisis estático
```

## Estructura
```
lib/
  core/            servicios y providers transversales (sync, credenciales...)
  config/theme/    tema y paleta (marca blanca)
  features/        auth, dashboard, sales, inventory, finance, settings, onboarding
supabase/          esquema, migraciones y script de reset
docs/              guías de operación y alta de clientes
```
