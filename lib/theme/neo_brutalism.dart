import 'package:flutter/material.dart';

/// Neo-brutalism theme for the app
class NeoBrutalismTheme {
  // Colors
  static const Color primary = Color(0xFF000000); // Black
  static const Color surface = Color(0xFFFAFAFA); // Off-white
  static const Color accent = Color(0xFFFFD60A); // Bright yellow
  static const Color border = Color(0xFF000000); // Black borders
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color error = Color(0xFFFF0000);

  // Border width
  static const double borderWidth = 3.0;
  static const double smallBorderWidth = 2.0;

  /// Neo-brutalism Card Style
  static BoxDecoration neoBrutalismCard({
    Color backgroundColor = surface,
    Color borderColor = border,
    double borderWidth_ = borderWidth,
    double shadowOffset = 8.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      border: Border.all(color: borderColor, width: borderWidth_),
      boxShadow: [
        BoxShadow(
          color: borderColor,
          offset: Offset(shadowOffset, shadowOffset),
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Neo-brutalism Button Style
  static BoxDecoration neoBrutalismButton({
    Color backgroundColor = primary,
    Color borderColor = primary,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: borderColor,
          offset: const Offset(3, 3),
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Get theme data
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        enableFeedback: true,
        landscapeLayout: BottomNavigationBarLandscapeLayout.linear,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: primary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Flashcard with neo-brutalism style
  static Widget brutalFlashcard({
    required String term,
    required String definition,
    bool isFlipped = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: neoBrutalismCard(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFlipped ? 'DEFINITION' : 'TERM',
              style: const TextStyle(
                color: textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFlipped ? definition : term,
              style: const TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Concept card with neo-brutalism style
  static Widget brutalConceptCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isFavorite = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: neoBrutalismCard(borderWidth_: smallBorderWidth),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isFavorite)
                  const Text(
                    '★',
                    style: TextStyle(
                      color: accent,
                      fontSize: 20,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Button with neo-brutalism style
  static Widget brutalButton({
    required String label,
    required VoidCallback onPressed,
    bool isOutlined = false,
    double padding = 16,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: neoBrutalismButton(
          backgroundColor: isOutlined ? surface : primary,
          borderColor: primary,
        ),
        padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding * 2),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isOutlined ? primary : surface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
