import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0A0E1A);
  static const Color gradientStart = Color(0xFFFF6FB1);
  static const Color gradientEnd = Color(0xFFFF9F66);
  static const Color surface = Colors.white10;
  static const Color border = Colors.white12;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark();

    // Typo: Space Grotesk for titres, Nunito pour textes.
    final bodyText = GoogleFonts.nunitoTextTheme(base.textTheme);
    final displayText = GoogleFonts.spaceGroteskTextTheme(bodyText).copyWith(
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: bodyText.headlineLarge?.fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: bodyText.headlineMedium?.fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: bodyText.headlineSmall?.fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.gradientStart,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gradientStart,
        secondary: AppColors.gradientEnd,
        background: AppColors.background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.gradientStart,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: displayText.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gradientStart),
        ),
      ),
    );
  }
}
