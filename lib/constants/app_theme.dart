import 'package:flutter/material.dart';

/// Campus Guide App Theme
/// Clean, production-ready design inspired by Google Maps
class AppTheme {
  AppTheme._();

  // ============================================
  // COLOR PALETTE
  // ============================================

  // Backgrounds
  static const Color bgPrimary = Color(0xFFFAFAFA);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color bgElevated = Color(0xFFF5F5F5);
  static const Color bgDark = Color(0xFF1A1A1A);

  // Campus Green (Primary)
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFFE8F5E9);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primarySurface = Color(0xFFC8E6C9);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Utility
  static const Color divider = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Building Type Colors
  static const Map<String, Color> buildingTypeColors = {
    'department': Color(0xFF1976D2),
    'amphitheatre': Color(0xFF7B1FA2),
    'library': Color(0xFF388E3C),
    'admin': Color(0xFFF57C00),
    'bloc': Color(0xFF00796B),
    'research': Color(0xFF303F9F),
    'other': Color(0xFF616161),
  };

  // ============================================
  // TYPOGRAPHY
  // ============================================

  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textHint,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  // ============================================
  // SPACING
  // ============================================

  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 24;
  static const double spacingXxl = 32;

  // ============================================
  // SHAPE
  // ============================================

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusFull = 100;

  static BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static BorderRadius borderRadiusFull = BorderRadius.circular(radiusFull);

  // ============================================
  // SHADOWS
  // ============================================

  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // ============================================
  // DECORATIONS
  // ============================================

  static BoxDecoration cardDecoration = BoxDecoration(
    color: bgSurface,
    borderRadius: borderRadiusMd,
    boxShadow: shadowSm,
  );

  static BoxDecoration searchBarDecoration = BoxDecoration(
    color: bgSurface,
    borderRadius: borderRadiusFull,
    boxShadow: shadowMd,
  );

  static BoxDecoration chipDecoration({bool isSelected = false}) {
    return BoxDecoration(
      color: isSelected ? primaryLight : bgSurface,
      borderRadius: borderRadiusFull,
      border: Border.all(
        color: isSelected ? primary : divider,
        width: 1,
      ),
    );
  }

  // ============================================
  // THEME DATA
  // ============================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: textOnPrimary,
        secondary: primaryLight,
        surface: bgSurface,
        onSurface: textPrimary,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSurface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingMedium,
      ),
      cardTheme: CardTheme(
        color: bgSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMd),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgSurface,
        selectedColor: primaryLight,
        labelStyle: labelMedium,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusFull),
        side: const BorderSide(color: divider),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgElevated,
        hintStyle: bodyMedium.copyWith(color: textHint),
        border: OutlineInputBorder(
          borderRadius: borderRadiusFull,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgSurface,
        selectedItemColor: primary,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textOnPrimary,
      ),
    );
  }
}

/// Animation durations for consistent timing across the app
class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration staggerDelay = Duration(milliseconds: 50);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
}
