import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Signature Tab Colors
  static const Color homeTeal = Color(0xFF1D9E75);
  static const Color studyPurple = Color(0xFF534AB7);
  static const Color visualizeAmber = Color(0xFFBA7517);
  static const Color profileTeal = Color(0xFF1D9E75);
  static const Color chatsPink = Color(0xFFD4537E);

  // Core System Colors
  static const Color primary = homeTeal;
  static const Color background = Color(0xFFF4F7F6);
  static const Color card = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color mutedText = Color(0xFF999999);
  static const Color cardBorder = Color(0x12000000); // rgba(0,0,0,0.07)
  
  static const Color coral = Color(0xFFE8735A);
  static const Color progressBg = Color(0xFFE1F5EE);
  static const Color lightTeal = Color(0xFFE1F5EE);
  static const Color tealHero = homeTeal;
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.card,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.outfitTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      useMaterial3: true,
    );
  }
}
