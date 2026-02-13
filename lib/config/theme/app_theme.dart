import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFEA4C3B); // Red Tomato
  static const Color secondaryColor = Color(0xFFF4A261); // Soft Orange
  static const Color backgroundColor = Color(0xFFFFFDF7); // Cream Paper
  static const Color cardColor = Color(0xFFFFFFFF); // Pure White
  static const Color titleColor = Color(0xFF2D2D2D); // Dark Grey
  static const Color bodyColor = Color(0xFF4A4A4A); // Medium Grey

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        background: backgroundColor,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.quicksand(
            color: titleColor, fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: GoogleFonts.quicksand(
            color: titleColor, fontWeight: FontWeight.bold, fontSize: 24),
        displaySmall: GoogleFonts.quicksand(
            color: titleColor, fontWeight: FontWeight.bold, fontSize: 20),
        titleLarge: GoogleFonts.quicksand(
            color: titleColor, fontWeight: FontWeight.bold, fontSize: 18),
        bodyLarge: GoogleFonts.quicksand(color: bodyColor, fontSize: 16),
        bodyMedium: GoogleFonts.quicksand(color: bodyColor, fontSize: 14),
      ),
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black, // simplified to remove withOpacity const issue if any
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: titleColor),
        titleTextStyle: GoogleFonts.quicksand(
          color: titleColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.quicksand(color: bodyColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: primaryColor),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: const Color(0xFF2C2C2C),
        background: const Color(0xFF121212),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.quicksand(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: GoogleFonts.quicksand(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        displaySmall: GoogleFonts.quicksand(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        titleLarge: GoogleFonts.quicksand(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        bodyLarge: GoogleFonts.quicksand(color: Colors.white70, fontSize: 16),
        bodyMedium: GoogleFonts.quicksand(color: Colors.white70, fontSize: 14),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF2C2C2C),
        elevation: 2,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.quicksand(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.quicksand(color: Colors.white70),
        hintStyle: GoogleFonts.quicksand(color: Colors.white38),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: primaryColor),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.1),
        thickness: 1,
      ),
    );
  }
}
