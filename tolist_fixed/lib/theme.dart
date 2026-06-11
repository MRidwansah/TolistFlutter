import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Background colors - from web design
  static const Color bgPrimary = Color(0xFF0B0F1A);     // Main dark bg
  static const Color bgSecondary = Color(0xFF111827);   // Sidebar/card bg
  static const Color bgCard = Color(0xFF161B22);        // Card surface

  // Accent colors
  static const Color indigo = Color(0xFF6366F1);        // Indigo-500
  static const Color indigoDark = Color(0xFF4F46E5);    // Indigo-600
  static const Color indigoFaint = Color(0x1A6366F1);   // Indigo-500/10

  // Status colors
  static const Color amber = Color(0xFFF59E0B);         // Amber-400
  static const Color emerald = Color(0xFF10B981);       // Emerald-500
  static const Color rose = Color(0xFFF43F5E);          // Rose-500
  static const Color sky = Color(0xFF0EA5E9);           // Sky-500

  // Text colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textSlate200 = Color(0xFFE2E8F0);
  static const Color textSlate400 = Color(0xFF94A3B8);
  static const Color textSlate500 = Color(0xFF64748B);
  static const Color textSlate600 = Color(0xFF475569);

  // Border colors
  static const Color borderSlate800 = Color(0xFF1E293B);
  static const Color borderSlate700 = Color(0xFF334155);
}

ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.indigo,
      surface: AppColors.bgCard,
    ),
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: AppColors.textWhite),
        displayMedium: TextStyle(color: AppColors.textWhite),
        displaySmall: TextStyle(color: AppColors.textWhite),
        headlineLarge: TextStyle(color: AppColors.textWhite),
        headlineMedium: TextStyle(color: AppColors.textWhite),
        headlineSmall: TextStyle(color: AppColors.textWhite),
        titleLarge: TextStyle(color: AppColors.textWhite),
        titleMedium: TextStyle(color: AppColors.textSlate200),
        titleSmall: TextStyle(color: AppColors.textSlate200),
        bodyLarge: TextStyle(color: AppColors.textSlate200),
        bodyMedium: TextStyle(color: AppColors.textSlate400),
        bodySmall: TextStyle(color: AppColors.textSlate500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x80000000),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderSlate800),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderSlate800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x806366F1)),
      ),
      hintStyle: const TextStyle(color: AppColors.textSlate600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );
}
