import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bgDeep = Color(0xFF060910);
  static const bg = Color(0xFF0A0E18);
  static const surface = Color(0xFF0F1420);
  static const surfaceRaised = Color(0xFF141A28);
  static const card = Color(0xFF111827);
  static const cardHover = Color(0xFF161E30);
  static const inputBg = Color(0xFF0D1219);
  static const border = Color(0x4D384E70);
  static const borderSubtle = Color(0x26384E70);
  static const borderGlow = Color(0x3350C8DC);

  static const text = Color(0xFFE8EDF5);
  static const textSecondary = Color(0xFF7A8BA8);
  static const textDim = Color(0xFF3E4D66);
  static const textBright = Color(0xFFFFFFFF);

  static const accent = Color(0xFF3ECFCF);
  static const accentDim = Color(0x263ECFCF);

  static const green = Color(0xFF22C55E);
  static const greenDim = Color(0x1F22C55E);
  static const red = Color(0xFFEF4444);
  static const redDim = Color(0x1FEF4444);
  static const yellow = Color(0xFFEAB308);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.dmSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.red,
        onPrimary: AppColors.bgDeep,
        onSecondary: AppColors.bgDeep,
        onSurface: AppColors.text,
        onError: AppColors.textBright,
        outline: AppColors.border,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDeep,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgDeep,
        indicatorColor: AppColors.accentDim,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.accent : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.accent : AppColors.textSecondary,
            size: 22,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.bgDeep,
        indicatorColor: AppColors.accentDim,
        selectedIconTheme: const IconThemeData(color: AppColors.accent),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textSecondary,
        ),
        selectedLabelTextStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
        unselectedLabelTextStyle: GoogleFonts.dmSans(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        hintStyle: GoogleFonts.dmSans(color: AppColors.textDim, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: GoogleFonts.dmSans(color: AppColors.text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextStyle get mono =>
      GoogleFonts.ibmPlexMono(fontSize: 13, color: AppColors.text);

  static TextStyle monoColored(Color color) =>
      GoogleFonts.ibmPlexMono(fontSize: 13, color: color);
}
