import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema base "Papelería cálida" (rediseño 2026): fondo crema, sidebar café
/// oscuro, titulares serif (Fraunces) y acentos terracota/verde.
///
/// La marca blanca sigue mandando: los colores configurables (primario,
/// acento, fondo, tarjetas) llegan como parámetros y sobrescriben estos
/// defaults. Estos valores solo definen el look de fábrica.
class AppTheme {
  // Paleta clara
  static const Color backgroundColor = Color(0xFFF7F1E8); // Crema cálido
  static const Color cardColor = Color(0xFFFFFFFF); // Blanco
  static const Color titleColor = Color(0xFF33291F); // Café oscuro
  static const Color bodyColor = Color(0xFF6E6257); // Gris cálido

  // Sidebar (oscuro en ambos temas, como el mockup)
  static const Color sidebarColor = Color(0xFF2A231C);
  static const Color sidebarColorDark = Color(0xFF201A14);

  // Paleta oscura
  static const Color darkBackground = Color(0xFF1B1511);
  static const Color darkCard = Color(0xFF272019);

  // Acentos por defecto (marca blanca los sobrescribe)
  static const Color defaultPrimary = Color(0xFFC4571F); // Terracota
  static const Color defaultSecondary = Color(0xFF1E7A4D); // Verde

  static TextTheme _textTheme(Color title, Color body) {
    return TextTheme(
      // Titulares en serif cálida (Fraunces), como el mockup.
      displayLarge: GoogleFonts.fraunces(
          color: title, fontWeight: FontWeight.w600, fontSize: 34),
      displayMedium: GoogleFonts.fraunces(
          color: title, fontWeight: FontWeight.w600, fontSize: 26),
      displaySmall: GoogleFonts.fraunces(
          color: title, fontWeight: FontWeight.w600, fontSize: 21),
      headlineSmall: GoogleFonts.fraunces(
          color: title, fontWeight: FontWeight.w600, fontSize: 19),
      titleLarge: GoogleFonts.quicksand(
          color: title, fontWeight: FontWeight.bold, fontSize: 18),
      bodyLarge: GoogleFonts.quicksand(color: body, fontSize: 16),
      bodyMedium: GoogleFonts.quicksand(color: body, fontSize: 14),
    );
  }

  static ThemeData lightTheme({
    Color primaryColor = defaultPrimary,
    Color secondaryColor = defaultSecondary,
    Color? background,
    Color? surface,
  }) {
    final bg = background ?? backgroundColor;
    final card = surface ?? cardColor;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: bg,
      ),
      textTheme: _textTheme(titleColor, bodyColor),
      cardTheme: CardThemeData(
        color: card,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: titleColor),
        titleTextStyle: GoogleFonts.fraunces(
          color: titleColor,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: titleColor.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.quicksand(color: bodyColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      iconTheme: IconThemeData(color: primaryColor),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: sidebarColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  static ThemeData darkTheme({
    Color primaryColor = defaultPrimary,
    Color secondaryColor = defaultSecondary,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkBackground,
      ),
      textTheme: _textTheme(Colors.white, Colors.white70),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 1,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.fraunces(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.quicksand(color: Colors.white70),
        hintStyle: GoogleFonts.quicksand(color: Colors.white38),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      iconTheme: IconThemeData(color: primaryColor),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: sidebarColorDark,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 1,
      ),
    );
  }
}
