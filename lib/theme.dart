/// SUGO – clean, minimal theme for mobile readability.
///
/// Neutral palette with a single moss-green accent.
/// System sans-serif font, generous touch targets, simple rounded corners.
library;

import 'package:flutter/material.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────

class SugoColors {
  SugoColors._();

  // Primary accent
  static const Color moss = Color(0xFF5B7553);
  static const Color mossLight = Color(0xFFD6E4D0);
  static const Color mossPale = Color(0xFFECF2E9);

  // Accent – used sparingly (FAB, warnings)
  static const Color terracotta = Color(0xFFBF7B5E);
  static const Color terracottaLight = Color(0xFFD9A68C);
  static const Color terracottaPale = Color(0xFFFAF0EB);

  // Neutrals
  static const Color sand = Color(0xFFF7F5F2);
  static const Color sandDark = Color(0xFFE8E4DE);
  static const Color parchment = Color(0xFFFAFAF8);
  static const Color warmGrey = Color(0xFF8C8278);
  static const Color bark = Color(0xFF2C2520);

  // Status – muted
  static const Color statusOk = Color(0xFF6B8F5E);
  static const Color statusWarning = Color(0xFFCB9B3E);
  static const Color statusDanger = Color(0xFFC26E5A);

  static const Color grain = Color(0x08000000);
}

// ─── Category visual identity ────────────────────────────────────────────────

class CategoryStyle {
  final IconData icon;
  final Color color;
  const CategoryStyle(this.icon, this.color);
}

CategoryStyle categoryStyleFor(String category) {
  final key = category.toLowerCase().trim();
  return _categoryMap[key] ??
      CategoryStyle(Icons.label_outline, SugoColors.warmGrey);
}

const _categoryMap = <String, CategoryStyle>{
  'dairy': CategoryStyle(Icons.water_drop_outlined, Color(0xFF7EACC1)),
  'bakery': CategoryStyle(Icons.bakery_dining_outlined, Color(0xFFCB9B3E)),
  'snacks': CategoryStyle(Icons.cookie_outlined, Color(0xFFD4915E)),
  'drinks': CategoryStyle(Icons.local_cafe_outlined, Color(0xFF8B6F5E)),
  'beverages': CategoryStyle(Icons.local_cafe_outlined, Color(0xFF8B6F5E)),
  'meat': CategoryStyle(Icons.restaurant_outlined, Color(0xFFC26E5A)),
  'seafood': CategoryStyle(Icons.set_meal_outlined, Color(0xFF5E8FAC)),
  'fruits': CategoryStyle(Icons.eco_outlined, Color(0xFF7BAF5E)),
  'vegetables': CategoryStyle(Icons.grass_outlined, Color(0xFF5B7553)),
  'frozen': CategoryStyle(Icons.ac_unit_outlined, Color(0xFF7EACC1)),
  'canned': CategoryStyle(Icons.inventory_2_outlined, Color(0xFF8C8278)),
  'condiments': CategoryStyle(Icons.opacity_outlined, Color(0xFFCB9B3E)),
  'spices': CategoryStyle(
    Icons.local_fire_department_outlined,
    Color(0xFFBF7B5E),
  ),
  'grains': CategoryStyle(Icons.grain_outlined, Color(0xFFAA8F6F)),
  'pasta': CategoryStyle(Icons.ramen_dining_outlined, Color(0xFFCB9B3E)),
  'cleaning': CategoryStyle(
    Icons.cleaning_services_outlined,
    Color(0xFF5E8FAC),
  ),
  'personal care': CategoryStyle(Icons.spa_outlined, Color(0xFFB07EAC)),
  'household': CategoryStyle(Icons.home_outlined, Color(0xFF8C8278)),
  'baby': CategoryStyle(Icons.child_care_outlined, Color(0xFFD4A0C0)),
  'pet': CategoryStyle(Icons.pets_outlined, Color(0xFF8B6F5E)),
  'other': CategoryStyle(Icons.label_outline, Color(0xFF8C8278)),
};

// ─── Border radii ────────────────────────────────────────────────────────────

class SugoBorders {
  SugoBorders._();

  static const BorderRadius card = BorderRadius.all(Radius.circular(14));
  static const BorderRadius sheet = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
  );
  static const BorderRadius chip = BorderRadius.all(Radius.circular(10));
  static const BorderRadius button = BorderRadius.all(Radius.circular(12));
}

// ─── Shadows ─────────────────────────────────────────────────────────────────

class SugoShadows {
  SugoShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withAlpha(10),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withAlpha(18),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

// ─── Theme data ──────────────────────────────────────────────────────────────

ThemeData sugoTheme() {
  const textColor = SugoColors.bark;
  const subtleColor = SugoColors.warmGrey;

  final textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    bodyLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: textColor,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: subtleColor,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: subtleColor,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: subtleColor,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: SugoColors.parchment,
    textTheme: textTheme,

    colorScheme: const ColorScheme.light(
      primary: SugoColors.moss,
      onPrimary: Colors.white,
      primaryContainer: SugoColors.mossPale,
      onPrimaryContainer: SugoColors.bark,
      secondary: SugoColors.terracotta,
      onSecondary: Colors.white,
      secondaryContainer: SugoColors.terracottaPale,
      onSecondaryContainer: SugoColors.bark,
      surface: SugoColors.parchment,
      onSurface: SugoColors.bark,
      surfaceContainerHighest: SugoColors.sandDark,
      error: SugoColors.statusDanger,
      onError: Colors.white,
      outline: SugoColors.warmGrey,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: SugoColors.parchment,
      foregroundColor: SugoColors.bark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: SugoColors.bark,
      ),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: SugoBorders.card),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: SugoColors.sand,
      selectedColor: SugoColors.mossPale,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: SugoBorders.chip),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SugoColors.moss,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: SugoBorders.button),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SugoColors.moss,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: SugoBorders.chip,
        borderSide: const BorderSide(color: SugoColors.sandDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: SugoBorders.chip,
        borderSide: const BorderSide(color: SugoColors.sandDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: SugoBorders.chip,
        borderSide: const BorderSide(color: SugoColors.moss, width: 1.5),
      ),
      labelStyle: const TextStyle(color: SugoColors.warmGrey, fontSize: 15),
      hintStyle: const TextStyle(color: SugoColors.warmGrey, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: SugoColors.moss,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: CircleBorder(),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: SugoColors.bark,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: SugoBorders.chip),
      behavior: SnackBarBehavior.floating,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: SugoColors.parchment,
      shape: RoundedRectangleBorder(borderRadius: SugoBorders.card),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: SugoColors.bark,
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: SugoBorders.chip),
    ),
  );
}
