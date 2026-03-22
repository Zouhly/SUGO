/// SUGO wabi-sabi theme – earth-inspired palette with organic warmth.
///
/// Moss greens, terracotta, sand tones. Serif fonts, soft shadows,
/// asymmetric rounded corners, grain textures, and natural imperfection.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Earth palette ───────────────────────────────────────────────────────────

class SugoColors {
  SugoColors._();

  // Primary – moss green
  static const Color moss = Color(0xFF5B7553);
  static const Color mossLight = Color(0xFF8FA787);
  static const Color mossPale = Color(0xFFD6E4D0);

  // Accent – terracotta
  static const Color terracotta = Color(0xFFBF7B5E);
  static const Color terracottaLight = Color(0xFFD9A68C);
  static const Color terracottaPale = Color(0xFFF2DDD3);

  // Neutral – sand
  static const Color sand = Color(0xFFF5EFE6);
  static const Color sandDark = Color(0xFFE8DFD0);
  static const Color parchment = Color(0xFFFAF7F2);
  static const Color warmGrey = Color(0xFF8C8278);
  static const Color bark = Color(0xFF4A3F35);

  // Status colours (muted, earthy)
  static const Color statusOk = Color(0xFF6B8F5E);
  static const Color statusWarning = Color(0xFFCB9B3E);
  static const Color statusDanger = Color(0xFFC26E5A);

  // Surface overlay for grain texture effect
  static const Color grain = Color(0x08000000);
}

// ─── Category visual identity ────────────────────────────────────────────────

class CategoryStyle {
  final IconData icon;
  final Color color;
  const CategoryStyle(this.icon, this.color);
}

/// Maps known category names to icons and colours.
/// Unknown categories get a fallback style.
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

// ─── Asymmetric border radii (wabi-sabi) ─────────────────────────────────────

class SugoBorders {
  SugoBorders._();

  /// Organic card shape – asymmetric corners
  static const BorderRadius card = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(12),
    bottomLeft: Radius.circular(14),
    bottomRight: Radius.circular(22),
  );

  /// Bottom sheet top corners
  static const BorderRadius sheet = BorderRadius.only(
    topLeft: Radius.circular(28),
    topRight: Radius.circular(18),
  );

  /// Chip / badge shape
  static const BorderRadius chip = BorderRadius.only(
    topLeft: Radius.circular(14),
    topRight: Radius.circular(10),
    bottomLeft: Radius.circular(10),
    bottomRight: Radius.circular(14),
  );

  /// Button shape
  static const BorderRadius button = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(10),
    bottomLeft: Radius.circular(12),
    bottomRight: Radius.circular(16),
  );
}

// ─── Shadows ─────────────────────────────────────────────────────────────────

class SugoShadows {
  SugoShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(
      color: SugoColors.bark.withAlpha(18),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: SugoColors.bark.withAlpha(30),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}

// ─── Theme data ──────────────────────────────────────────────────────────────

ThemeData sugoTheme() {
  final textTheme = GoogleFonts.loraTextTheme().copyWith(
    // Display/headline – heavier serif
    displayLarge: GoogleFonts.lora(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: SugoColors.bark,
    ),
    displayMedium: GoogleFonts.lora(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: SugoColors.bark,
    ),
    headlineLarge: GoogleFonts.lora(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: SugoColors.bark,
    ),
    headlineMedium: GoogleFonts.lora(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: SugoColors.bark,
    ),
    headlineSmall: GoogleFonts.lora(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: SugoColors.bark,
    ),
    // Title
    titleLarge: GoogleFonts.lora(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: SugoColors.bark,
    ),
    titleMedium: GoogleFonts.lora(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: SugoColors.bark,
    ),
    titleSmall: GoogleFonts.lora(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: SugoColors.bark,
    ),
    // Body – lighter serif for readability
    bodyLarge: GoogleFonts.lora(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: SugoColors.bark,
    ),
    bodyMedium: GoogleFonts.lora(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: SugoColors.bark,
    ),
    bodySmall: GoogleFonts.lora(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: SugoColors.warmGrey,
    ),
    // Label
    labelLarge: GoogleFonts.lora(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: SugoColors.bark,
    ),
    labelMedium: GoogleFonts.lora(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: SugoColors.warmGrey,
    ),
    labelSmall: GoogleFonts.lora(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: SugoColors.warmGrey,
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

    appBarTheme: AppBarTheme(
      backgroundColor: SugoColors.parchment,
      foregroundColor: SugoColors.bark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.lora(
        fontSize: 20,
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
      labelStyle: GoogleFonts.lora(fontSize: 13, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: SugoBorders.chip),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SugoColors.moss,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: SugoBorders.button),
        textStyle: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SugoColors.moss,
        textStyle: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: SugoBorders.chip,
        borderSide: BorderSide(color: SugoColors.sandDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: SugoBorders.chip,
        borderSide: BorderSide(color: SugoColors.sandDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: SugoBorders.chip,
        borderSide: const BorderSide(color: SugoColors.moss, width: 1.5),
      ),
      labelStyle: GoogleFonts.lora(color: SugoColors.warmGrey),
      hintStyle: GoogleFonts.lora(color: SugoColors.warmGrey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: SugoColors.terracotta,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: SugoColors.bark,
      contentTextStyle: GoogleFonts.lora(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: SugoBorders.chip),
      behavior: SnackBarBehavior.floating,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: SugoColors.parchment,
      shape: RoundedRectangleBorder(borderRadius: SugoBorders.card),
      titleTextStyle: GoogleFonts.lora(
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
