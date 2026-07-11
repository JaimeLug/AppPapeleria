# Guía: dar de alta un cliente nuevo

Papelería Pro es marca blanca: cada cliente puede tener **su propia base de
datos** (Supabase) y **su propia imagen** (nombre, logo, colores). Esta guía
cubre los dos escenarios.

---

## Escenario A — Cliente con su propia base de datos (recomendado)

Cada cliente tiene sus datos aislados. Es lo ideal para clientes reales.

### 1. Crear el proyecto de Supabase
1. Entra a <https://supabase.com> → **New project** (plan Free alcanza).
2. Anota la contraseña de la base de datos (por si acaso).
3. Espera a que el proyecto termine de crearse.

### 2. Cargar el esquema
1. En el proyecto: **SQL Editor → New query**.
2. Pega **todo** el contenido de [`supabase/schema.sql`](../supabase/schema.sql) y dale **Run**.
   - Ya incluye tablas, RLS, Realtime, el trigger de `updated_at` y los
     colores de marca. Es idempotente (se puede correr de nuevo sin romper).

### 3. Crear la cuenta del cliente
1. **Authentication → Users → Add user**.
2. Pon el correo y contraseña del cliente. **Marca "Auto Confirm User"**
   (si no, no podrá entrar sin verificar el correo).

### 4. Obtener las credenciales
1. **Project Settings → Data API** (o **API**).
2. Copia el **Project URL** (`https://xxxxx.supabase.co`).
3. Copia la **anon / publishable key** (NO la `service_role`).

### 5. Entregar la app
Instala la app con el instalador (ver [abajo](#compilar-el-instalador)) y en
la **primera apertura**, en el asistente de bienvenida:
- Paso **Base de datos → "Conectar otra base de datos"** → pega el Project URL
  y la anon key → **Guardar conexión** → **cierra y vuelve a abrir la app**.
- Vuelve a abrir → **Iniciar sesión** con la cuenta del paso 3.
- Nombre, logo y colores → **Listo**.

> Alternativa: puedes armar un instalador con el `.env` del cliente ya puesto
> (así no tiene que ingresar nada). Ver la sección del `.env` más abajo.

---

## Escenario B — Cliente que comparte tu base (familiar/interno)

Usa la base de datos actual (la del `.env` que ya trae la app). No hay que
configurar nada de conexión: en el asistente, el paso **Base de datos** dirá
"Conectada por defecto". Solo inicia sesión con una cuenta que tú crees en tu
proyecto de Supabase (**Authentication → Users → Add user**, con Auto Confirm).

⚠️ Comparten datos: ambos ven el mismo negocio. Solo para familiares/internos.

---

## Compilar el instalador

1. Genera el build de Windows:
   ```
   flutter build windows --release
   ```
2. Abre [`installer_papeleria_pro.iss`](../installer_papeleria_pro.iss) con
   **Inno Setup** y presiona **Compilar** (o corre `ISCC installer_papeleria_pro.iss`).
3. El instalador queda en `Output\PapeleriaPro_v100_Setup.exe`.
4. Ese `.exe` es el que le pasas al cliente.

> El instalador NO borra los datos locales (Hive vive en `%APPDATA%`), así que
> una reinstalación/actualización conserva la información. Además todo se
> sincroniza a Supabase.

---

## Sobre el `.env` (conexión por defecto)

- El archivo `.env` (en la raíz, no versionado) trae `SUPABASE_URL` y
  `SUPABASE_ANON_KEY`. Es la **conexión por defecto** que se empaqueta en el
  instalador.
- La app da prioridad a las credenciales que el usuario guarde en el asistente
  **sobre** el `.env`. Por eso un cliente puede conectar su propia base sin que
  tengas que rearmar el instalador.
- Si quieres un instalador que ya venga con la base de un cliente concreto:
  cambia el `.env` a esa base antes de `flutter build windows --release`.

Formato del `.env` (ver `.env.example`):
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...
```
