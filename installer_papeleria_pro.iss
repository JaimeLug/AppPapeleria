; ============================================================================
; Instalador de Papelería Pro (Windows) — Inno Setup
; ----------------------------------------------------------------------------
; Cómo compilarlo:
;   1) Genera el build:   flutter build windows --release
;   2) Abre este archivo con Inno Setup y presiona Compilar (o corre ISCC).
;   3) El instalador queda en la carpeta Output\.
;
; Notas:
;  * El .exe de Flutter se llama app_papeleria.exe y aquí se renombra a
;    "Papeleria Pro.exe" en la carpeta de destino.
;  * Los datos locales (Hive) viven en %APPDATA%; el instalador NO los toca,
;    así que se conservan entre actualizaciones.
;  * Para un cliente con su propia base de datos: la app pide la conexión en
;    el asistente de bienvenida (no hay que rearmar el instalador). Ver
;    docs/GUIA_ALTA_CLIENTE.md.
; ============================================================================

#define MyAppName "Papelería Pro"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Jaime Lugo"
#define MyAppExeName "Papeleria Pro.exe"
; AppId nuevo para la marca Papelería Pro. NO reutilizar en otras apps.
#define MyAppId "{{7E2A1F94-3C6D-4B8A-9E1C-A2D5F0B76C31}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=admin
OutputDir=Output
OutputBaseFilename=PapeleriaPro_v100_Setup
SetupIconFile=c:\Users\jaime\AppPapeleria\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "c:\Users\jaime\AppPapeleria\build\windows\x64\runner\Release\app_papeleria.exe"; DestDir: "{app}"; DestName: "{#MyAppExeName}"; Flags: ignoreversion
Source: "c:\Users\jaime\AppPapeleria\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "c:\Users\jaime\AppPapeleria\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Persistencia: Hive guarda los datos en %APPDATA%. Este instalador no toca
// esa carpeta, así que la base local se conserva entre reinstalaciones. De
// todas formas los datos se sincronizan a Supabase.
