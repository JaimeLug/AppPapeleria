import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// Muestra el logo del negocio si se ha subido uno (guardado en la marca),
/// o el logo por defecto de la app como respaldo. Se actualiza solo cuando
/// cambia la configuración de marca.
class BrandLogo extends ConsumerWidget {
  final double height;
  final BoxFit fit;

  const BrandLogo({super.key, this.height = 40, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoBase64 =
        ref.watch(currentBrandConfigProvider.select((c) => c.logoBase64));

    if (logoBase64 != null && logoBase64.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(logoBase64),
          height: height,
          fit: fit,
        );
      } catch (_) {
        // base64 corrupto -> caemos al logo por defecto.
      }
    }

    return Image.asset('assets/images/logo.png', height: height, fit: fit);
  }
}
