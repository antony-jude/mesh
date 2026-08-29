import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Emergency Color Palette
  static const Color bgDarkest = Color(0xFF0A0E17);
  static const Color bgSurface = Color(0xFF131B2A);
  static const Color bgCard = Color(0xFF1A2438);
  static const Color bgCardHover = Color(0xFF22304A);
  
  static const Color borderSubtle = Color(0xFF26354E);
  static const Color borderBright = Color(0xFF3B527A);

  static const Color primary = Color(0xFF38BDF8); // Electric Sky Blue
  static const Color primaryContainer = Color(0xFF0C4A6E);
  
  static const Color meshGreen = Color(0xFF22C55E); // Connected Mesh Green
  static const Color meshYellow = Color(0xFFEAB308); // Limited Mesh Yellow
  static const Color meshRed = Color(0xFFEF4444); // Isolated / Emergency Red
  static const Color emergencyAccent = Color(0xFFFF334B);

  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDarkest,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: meshGreen,
        surface: bgSurface,

        error: meshRed,
        onPrimary: Color(0xFF07090E),
        onSurface: textMain,

      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.orbitron(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: textMain,
          letterSpacing: 1.2,
        ),
        headlineMedium: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textMain,
          letterSpacing: 1.0,
        ),
        headlineSmall: GoogleFonts.orbitron(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textMain,
          letterSpacing: 0.8,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textMain,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textMain,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textMain,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelSmall: GoogleFonts.firaCode(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textDim,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
    );
  }
}

