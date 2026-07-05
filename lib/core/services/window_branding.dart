import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

bool get _supported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// Aplica el logo del negocio como ícono de la ventana y de la barra de tareas
/// (en tiempo real). En Windows `setIcon` exige un `.ico`, así que convertimos
/// el logo (PNG/JPG) a ICO al vuelo. Si no hay logo, usa el logo por defecto.
Future<void> applyWindowIcon(String? logoBase64) async {
  if (!_supported) return;
  try {
    final Uint8List sourceBytes;
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      sourceBytes = base64Decode(logoBase64);
    } else {
      final data = await rootBundle.load('assets/images/logo.png');
      sourceBytes = data.buffer.asUint8List();
    }

    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) return;

    // Redimensionamos a 128px (ICO admite hasta 256) para un ícono ligero.
    final resized = img.copyResize(decoded, width: 128);
    final icoBytes = img.encodeIco(resized);

    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/window_icon.ico');
    await file.writeAsBytes(icoBytes);

    await windowManager.setIcon(file.path);
  } catch (_) {
    // Silencioso: si algo falla, se conserva el ícono por defecto.
  }
}
