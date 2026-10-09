// Adaptive theme: the surface/text/border colors below resolve to the dark or
// light palette depending on ThemeController.instance.isDark. Brand colors,
// status colors, category colors and gradients stay constant in both modes.
// Scaffold.backgroundColor = AppTheme.backgroundLight (adaptive) — ALL screens

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme_controller.dart';

class AppTheme {
  // ── Design Tokens (shared system-wide) ────────────────────────
  // Radii
  static const double radiusInput = 12;
  static const double radiusCard = 16;
  static const double radiusSheet = 24;
  static const double radiusPill = 100;
  static const double radiusControl = 8;
  // Spacing
  static const double pagePadding = 20;
  static const double sectionSpacing = 24;
  static const double gridSpacing = 12;
  // Icon sizes
  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 22;
  static const double iconLg = 24;
  // Standard controls
  static const double backButtonSize = 40;
  static const double searchBarHeight = 48;
  static const double chipHeight = 36;
  // Typography (font sizes; use with .sp on the theme side)
  static const double titlePageSize = 20;
  static const double titleSectionSize = 18;
  static const double titleResultSize = 16;
  static const FontWeight titlePageWeight = FontWeight.w800;
  static const FontWeight titleSectionWeight = FontWeight.w700;

  // ── Brand Colors ──────────────────────────────────────────────
  static const Color primaryPink = Color(0xFFEFA9B8);
  static const Color primaryPinkLight = Color(0xFFF6D9E4);
  static const Color primaryPinkDark = Color(0xFFD898AA);
  static const Color goldAccent = Color(0xFFC8A96A);
  static const Color goldLight = Color(0xFFE8D5A3);

  // ── Backgrounds ────────────────────────────────────────────────
  // Adaptive: return the dark value when the app is in dark mode.
  static const Color _backgroundLight = Color(0xFFFFF8F3);
  static const Color backgroundDark = Color(0xFF1C1C1E);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2D2D2D);
  static const Color _ivoryLight = Color(0xFFFAF6F0);
  static const Color _ivoryDark = Color(0xFF2A2A2A);

  // ── Text (adaptive) ────────────────────────────────────────────
  static const Color _charcoal = Color(0xFF2D2D2D);
  static const Color _onDark = Color(0xFFE6E6E6);
  static const Color charcoalDark = Color(0xFF1C1C1E);
  static const Color _grayText = Color(0xFF777777);
  static const Color _onDarkMuted = Color(0xFFAAAAAA);
  static const Color _grayLight = Color(0xFFBBBBBB);
  static const Color _grayLightDark = Color(0xFF666666);

  // ── Borders (adaptive) ─────────────────────────────────────────
  static const Color _borderLight = Color(0xFFE9E1D8);
  static const Color _borderLightDark = Color(0xFF3A3A3A);
  static const Color _borderMedium = Color(0xFFDDD5CC);
  static const Color _borderMediumDark = Color(0xFF444444);

  static bool get _isDark => ThemeController.instance.isDark;

  static Color get backgroundLight => _isDark ? backgroundDark : _backgroundLight;
  static Color get surfaceLight => _isDark ? surfaceDark : _surfaceLight;
  static Color get ivoryLight => _isDark ? _ivoryDark : _ivoryLight;
  static Color get charcoal => _isDark ? _onDark : _charcoal;
  static Color get grayText => _isDark ? _onDarkMuted : _grayText;
  static Color get grayLight => _isDark ? _grayLightDark : _grayLight;
  static Color get borderLight => _isDark ? _borderLightDark : _borderLight;
  static Color get borderMedium => _isDark ? _borderMediumDark : _borderMedium;

  // ── Tinted surfaces (adaptive pastels) ─────────────────────────
  static const Color _tintPink = Color(0xFFF6D9E4);
  static const Color _tintPinkDark = Color(0xFF3A2C33);
  static const Color _tintPinkLight = Color(0xFFFDE8F7);
  static const Color _tintPinkLightDark = Color(0xFF3D2F3A);
  static const Color _tintPeach = Color(0xFFF7E8D6);
  static const Color _tintPeachDark = Color(0xFF383229);
  static const Color _tintPeachLight = Color(0xFFFFEDE6);
  static const Color _tintPeachLightDark = Color(0xFF3A2D28);
  static const Color _tintLavender = Color(0xFFF3EEFF);
  static const Color _tintLavenderDark = Color(0xFF2F2B3A);
  static const Color _tintCream = Color(0xFFFFF8F3);
  static const Color _tintCreamDark = Color(0xFF2F2C29);
  static const Color _tintCreamWarm = Color(0xFFFFF8EC);
  static const Color _tintCreamWarmDark = Color(0xFF302C27);
  static const Color _tintCreamSoft = Color(0xFFFFF8F0);
  static const Color _tintCreamSoftDark = Color(0xFF2F2C29);
  static const Color _tintOrangeLight = Color(0xFFFFF0E0);
  static const Color _tintOrangeLightDark = Color(0xFF382E26);
  static const Color _tintOrangeMist = Color(0xFFFFF7ED);
  static const Color _tintOrangeMistDark = Color(0xFF38312A);
  static const Color _tintYellow = Color(0xFFFFF0D0);
  static const Color _tintYellowDark = Color(0xFF3A3526);
  static const Color _tintLemon = Color(0xFFFFFBEB);
  static const Color _tintLemonDark = Color(0xFF3A3728);
  static const Color _tintLemonWarm = Color(0xFFFFFDE7);
  static const Color _tintLemonWarmDark = Color(0xFF3A3728);
  static const Color _tintPinkMist = Color(0xFFFDF2F8);
  static const Color _tintPinkMistDark = Color(0xFF3A2E36);
  static const Color _tintVioletMist = Color(0xFFFAF5FF);
  static const Color _tintVioletMistDark = Color(0xFF302D3A);
  static const Color _tintGreenMist = Color(0xFFF0FDF4);
  static const Color _tintGreenMistDark = Color(0xFF2A352C);
  static const Color _tintPurpleLight = Color(0xFFF3E8FF);
  static const Color _tintPurpleLightDark = Color(0xFF332A3D);
  static const Color _tintRose = Color(0xFFFFE5E3);
  static const Color _tintRoseDark = Color(0xFF3B2B2A);
  static const Color _tintAmber = Color(0xFFFFF3DC);
  static const Color _tintAmberDark = Color(0xFF393224);
  static const Color _tintAmberLight = Color(0xFFFFF3E0);
  static const Color _tintAmberLightDark = Color(0xFF393024);
  static const Color _tintRed = Color(0xFFFFEEEE);
  static const Color _tintRedDark = Color(0xFF3B2A2A);
  static const Color _tintBlush = Color(0xFFFFF0F5);
  static const Color _tintBlushDark = Color(0xFF3A2E36);
  static const Color _tintGreenDark = Color(0xFF2B362C);
  static const Color _tintBlueDark = Color(0xFF2B323A);
  static const Color _tintBlueSoft = Color(0xFFE8F4FD);
  static const Color _tintBlueSoftDark = Color(0xFF2B323A);
  static const Color _tintNeutral = Color(0xFFF0EDED);
  static const Color _tintNeutralDark = Color(0xFF333333);
  static const Color _tintSalonDark = Color(0xFF322C3A);
  static const Color _tintGymDark = Color(0xFF3A2E26);

  static Color get tintPink => _isDark ? _tintPinkDark : _tintPink;
  static Color get tintPinkLight => _isDark ? _tintPinkLightDark : _tintPinkLight;
  static Color get tintPeach => _isDark ? _tintPeachDark : _tintPeach;
  static Color get tintPeachLight => _isDark ? _tintPeachLightDark : _tintPeachLight;
  static Color get tintLavender => _isDark ? _tintLavenderDark : _tintLavender;
  static Color get tintCream => _isDark ? _tintCreamDark : _tintCream;
  static Color get tintCreamWarm => _isDark ? _tintCreamWarmDark : _tintCreamWarm;
  static Color get tintCreamSoft => _isDark ? _tintCreamSoftDark : _tintCreamSoft;
  static Color get tintOrangeLight => _isDark ? _tintOrangeLightDark : _tintOrangeLight;
  static Color get tintOrangeMist => _isDark ? _tintOrangeMistDark : _tintOrangeMist;
  static Color get tintYellow => _isDark ? _tintYellowDark : _tintYellow;
  static Color get tintLemon => _isDark ? _tintLemonDark : _tintLemon;
  static Color get tintLemonWarm => _isDark ? _tintLemonWarmDark : _tintLemonWarm;
  static Color get tintPinkMist => _isDark ? _tintPinkMistDark : _tintPinkMist;
  static Color get tintVioletMist => _isDark ? _tintVioletMistDark : _tintVioletMist;
  static Color get tintGreenMist => _isDark ? _tintGreenMistDark : _tintGreenMist;
  static Color get tintPurpleLight => _isDark ? _tintPurpleLightDark : _tintPurpleLight;
  static Color get tintRose => _isDark ? _tintRoseDark : _tintRose;
  static Color get tintAmber => _isDark ? _tintAmberDark : _tintAmber;
  static Color get tintAmberLight => _isDark ? _tintAmberLightDark : _tintAmberLight;
  static Color get tintRed => _isDark ? _tintRedDark : _tintRed;
  static Color get tintBlush => _isDark ? _tintBlushDark : _tintBlush;
  static Color get tintGreen => _isDark ? _tintGreenDark : Color(0xFFDDF6E3);
  static Color get tintBlue => _isDark ? _tintBlueDark : Color(0xFFDDEAFE);
  static Color get tintBlueSoft => _isDark ? _tintBlueSoftDark : _tintBlueSoft;
  static Color get tintNeutral => _isDark ? _tintNeutralDark : _tintNeutral;
  static Color get tintSalon => _isDark ? _tintSalonDark : Color(0xFFE9DDF7);
  static Color get tintGym => _isDark ? _tintGymDark : Color(0xFFFFE3D1);

  // ── Category Colors ────────────────────────────────────────────
  static const Color realEstate = Color(0xFFD898AA);
  static const Color fashion = Color(0xFFEFA9B8);
  static const Color clinics = Color(0xFFE787C9);
  static const Color gym = Color(0xFF8FD9F7);
  static const Color jobs = Color(0xFFC9D9FF);
  static const Color salons = Color(0xFFDCCFE8);

  // ── Category Background Colors (adaptive) ──────────────────────
  static Color get fashionBg => _isDark ? _tintPinkDark : Color(0xFFF6D9E4);
  static Color get realEstateBg => _isDark ? _tintPeachDark : Color(0xFFF7E8D6);
  static Color get clinicsBg => _isDark ? _tintBlueDark : Color(0xFFDDEAFE);
  static Color get salonsBg => _isDark ? _tintSalonDark : Color(0xFFE9DDF7);
  static Color get jobsBg => _isDark ? _tintGreenDark : Color(0xFFDDF6E3);
  static Color get gymBg => _isDark ? _tintGymDark : Color(0xFFFFE3D1);

  // ── Status Colors ──────────────────────────────────────────────
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFFB547);
  static const Color error = Color(0xFFFF5C5C);
  static const Color info = Color(0xFF5DADE2);

  // ── Gradients ──────────────────────────────────────────────────
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7DDE4), Color(0xFFFFF6EC), Color(0xFFE9C99A)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEFA9B8), Color(0xFFC8A96A)],
  );

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5D8E4), Color(0xFF8FD9F7)],
  );

  // ── Light Theme ────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryPink,
      onPrimary: Colors.white,
      primaryContainer: primaryPinkLight,
      onPrimaryContainer: charcoalDark,
      secondary: goldAccent,
      onSecondary: Colors.white,
      secondaryContainer: goldLight,
      onSecondaryContainer: charcoalDark,
      surface: surfaceLight,
      onSurface: charcoal,
      surfaceContainerHighest: ivoryLight,
      onSurfaceVariant: grayText,
      error: error,
      onError: Colors.white,
      outline: borderLight,
      outlineVariant: borderMedium,
      shadow: Color(0x14000000),
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.cairoTextTheme().copyWith(
      displayLarge: GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: charcoal,
        letterSpacing: -0.3,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: charcoal,
        letterSpacing: -0.3,
      ),
      headlineLarge: GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: charcoal,
        letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: charcoal,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: charcoal,
        letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: charcoal,
        letterSpacing: -0.3,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: charcoal,
        letterSpacing: -0.3,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: charcoal,
        letterSpacing: -0.3,
      ),
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: charcoal,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: charcoal,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: grayText,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: charcoal,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: charcoal,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: grayText,
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: charcoal,
      ),
      iconTheme: IconThemeData(color: charcoal, size: 24),
    ),
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderLight, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryPink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.cairo(fontSize: 14, color: grayText),
      labelStyle: GoogleFonts.cairo(fontSize: 14, color: grayText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryPink,
        side: const BorderSide(color: primaryPink, width: 1.5),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ivoryLight,
      selectedColor: primaryPinkLight,
      labelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500),
      side: BorderSide(color: borderLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: borderLight,
      thickness: 1,
      space: 0,
    ),
    iconTheme: IconThemeData(color: charcoal, size: 24),
  );

  // ── Dark Theme ─────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: primaryPink,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF6B3040),
      onPrimaryContainer: Color(0xFFF6D9E4),
      secondary: goldAccent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF5A4420),
      onSecondaryContainer: goldLight,
      surface: surfaceDark,
      onSurface: _onDark,
      surfaceContainerHighest: Color(0xFF3A3A3A),
      onSurfaceVariant: _onDarkMuted,
      error: Color(0xFFCF6679),
      onError: Colors.white,
      outline: _borderMediumDark,
      outlineVariant: _borderLightDark,
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.cairoTextTheme().copyWith(
      displayLarge: GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: _onDark,
        letterSpacing: 0,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: _onDark,
        letterSpacing: 0,
      ),
      headlineLarge: GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: _onDark,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _onDark,
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _onDark,
        letterSpacing: 0,
      ),
      titleLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _onDark,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _onDark,
        letterSpacing: 0,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _onDark,
        letterSpacing: 0,
      ),
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: _onDark,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _onDark,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: _onDarkMuted,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _onDark,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _onDark,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _onDarkMuted,
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _onDark,
      ),
      iconTheme: IconThemeData(color: _onDark, size: 24),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _borderLightDark, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderLightDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderLightDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryPink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFCF6679)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.cairo(fontSize: 14, color: _onDarkMuted),
      labelStyle: GoogleFonts.cairo(fontSize: 14, color: _onDarkMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryPink,
        side: const BorderSide(color: primaryPink, width: 1.5),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _ivoryDark,
      selectedColor: Color(0xFF6B3040),
      labelStyle: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _onDark,
      ),
      side: BorderSide(color: _borderLightDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: _borderLightDark,
      thickness: 1,
      space: 0,
    ),
    iconTheme: IconThemeData(color: _onDark, size: 24),
  );

  // ── Arabic Theme (Cairo font + RTL) ────────────────────────────
  static ThemeData get arabicTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryPink,
      onPrimary: Colors.white,
      primaryContainer: primaryPinkLight,
      onPrimaryContainer: charcoalDark,
      secondary: goldAccent,
      onSecondary: Colors.white,
      secondaryContainer: goldLight,
      onSecondaryContainer: charcoalDark,
      surface: surfaceLight,
      onSurface: charcoal,
      surfaceContainerHighest: ivoryLight,
      onSurfaceVariant: grayText,
      error: error,
      onError: Colors.white,
      outline: borderLight,
      outlineVariant: borderMedium,
      shadow: Color(0x14000000),
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.cairoTextTheme().copyWith(
      displayLarge: GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: charcoal,
        letterSpacing: 0,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: charcoal,
        letterSpacing: 0,
      ),
      headlineLarge: GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: charcoal,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: charcoal,
        letterSpacing: 0,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: charcoal,
        letterSpacing: 0,
      ),
      titleLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: charcoal,
        letterSpacing: 0,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: charcoal,
        letterSpacing: 0,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: charcoal,
        letterSpacing: 0,
      ),
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: charcoal,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: charcoal,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: grayText,
        height: 1.6,
      ),
      labelLarge: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: charcoal,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: charcoal,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: grayText,
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: charcoal,
      ),
      iconTheme: IconThemeData(color: charcoal, size: 24),
    ),
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderLight, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryPink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.cairo(fontSize: 14, color: grayText),
      labelStyle: GoogleFonts.cairo(fontSize: 14, color: grayText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryPink,
        side: const BorderSide(color: primaryPink, width: 1.5),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ivoryLight,
      selectedColor: primaryPinkLight,
      labelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500),
      side: BorderSide(color: borderLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: borderLight,
      thickness: 1,
      space: 0,
    ),
    iconTheme: IconThemeData(color: charcoal, size: 24),
  );
}
