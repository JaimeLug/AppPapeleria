import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Crea un acceso directo en el escritorio de Windows que apunta a esta app,
/// pero usando el logo de la marca como ícono. Así cada negocio tiene el ícono
/// de SU marca en su acceso directo sin recompilar el .exe (el ícono del
/// ejecutable es build-time; el del acceso directo sí se puede personalizar).
///
/// Devuelve null si tuvo éxito, o un mensaje de error para mostrar al usuario.
Future<String?> createBrandDesktopShortcut({
  required String appName,
  required String? logoBase64,
}) async {
  if (!Platform.isWindows) {
    return 'Los accesos directos con logo solo están disponibles en Windows.';
  }
  try {
    // 1. Genera el .ico del logo (o el logo por defecto) en una ruta estable
    //    (el acceso directo referencia este archivo, así que debe persistir).
    final Uint8List sourceBytes;
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      sourceBytes = base64Decode(logoBase64);
    } else {
      final data = await rootBundle.load('assets/images/logo.png');
      sourceBytes = data.buffer.asUint8List();
    }
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) return 'No se pudo leer el logo.';
    final icoBytes = img.encodeIco(img.copyResize(decoded, width: 256));

    final dir = await getApplicationSupportDirectory();
    final icoFile = File('${dir.path}\\shortcut_icon.ico');
    await icoFile.writeAsBytes(icoBytes);

    // 2. Ejecutable y su carpeta.
    final exePath = Platform.resolvedExecutable;
    final exeDir = File(exePath).parent.path;

    // 3. Nombre del acceso directo (sin caracteres inválidos ni comillas).
    final safeName =
        appName.replaceAll(RegExp('''[\\\\/:*?"<>|']'''), '').trim();
    final shortcutName = safeName.isEmpty ? 'Papeleria Pro' : safeName;

    // 4. Escribe el script a un .ps1 temporal (con BOM UTF-8 para los acentos)
    //    y lo ejecuta con -File; es mucho más robusto que un -Command multilínea.
    final script = '''
\$desktop = [Environment]::GetFolderPath('Desktop')
\$ws = New-Object -ComObject WScript.Shell
\$sc = \$ws.CreateShortcut([System.IO.Path]::Combine(\$desktop, '$shortcutName.lnk'))
\$sc.TargetPath = '$exePath'
\$sc.IconLocation = '${icoFile.path}'
\$sc.WorkingDirectory = '$exeDir'
\$sc.Save()
''';

    final ps1 = File('${dir.path}\\create_shortcut.ps1');
    await ps1.writeAsBytes([
      0xEF, 0xBB, 0xBF, // BOM UTF-8
      ...utf8.encode(script),
    ]);

    final result = await Process.run(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ps1.path],
    );

    if (result.exitCode != 0) {
      return 'No se pudo crear el acceso directo: ${result.stderr}';
    }
    return null; // éxito
  } catch (e) {
    return 'Error creando el acceso directo: $e';
  }
}
