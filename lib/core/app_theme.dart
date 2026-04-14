import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Palette ────────────────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF4A6741); // forest green (leaf)
  static const Color primaryLight   = Color(0xFFD6E4D0); // soft green tint
  static const Color secondary      = Color(0xFFC8622A); // terracotta
  static const Color secondaryLight = Color(0xFFF5DDD0); // soft terracotta tint
  static const Color accent         = Color(0xFFD4A017); // golden amber
  static const Color background     = Color(0xFFFDF6EC); // warm cream
  static const Color surface        = Color(0xFFF5EDD8); // parchment
  static const Color surfaceHigh    = Color(0xFFEDE0C4); // slightly deeper parchment
  static const Color onBackground   = Color(0xFF2C1503); // espresso
  static const Color onSurface      = Color(0xFF2C1503); // espresso
  static const Color onPrimary      = Color(0xFFFDF6EC); // cream on green
  static const Color textMuted      = Color(0xFF7A5C3E); // warm medium brown
  static const Color divider        = Color(0xFFDDD0B8); // warm divider
  static const Color error          = Color(0xFF7A1C1C); // deep crimson

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.light(
        primary:          primary,
        onPrimary:        onPrimary,
        secondary:        secondary,
        onSecondary:      onPrimary,
        tertiary:         accent,
        surface:          surface,
        onSurface:        onSurface,
        surfaceContainerHighest: surfaceHigh,
        error:            error,
        onError:          onPrimary,
      ),
      scaffoldBackgroundColor: background,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: divider,
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        iconTheme: const IconThemeData(color: onSurface),
      ),

      // ── Typography ──────────────────────────────────────────────────────────
      // DM Serif Display for headings, DM Sans for body — literary but legible
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge:  GoogleFonts.dmSerifDisplay(color: onSurface),
        displayMedium: GoogleFonts.dmSerifDisplay(color: onSurface),
        displaySmall:  GoogleFonts.dmSerifDisplay(color: onSurface),
        headlineLarge: GoogleFonts.dmSerifDisplay(color: onSurface),
        headlineMedium:GoogleFonts.dmSerifDisplay(color: onSurface),
        headlineSmall: GoogleFonts.dmSerifDisplay(color: onSurface),
        titleLarge:    GoogleFonts.dmSerifDisplay(fontSize: 20, color: onSurface),
        titleMedium:   GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
        titleSmall:    GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
        bodyLarge:     GoogleFonts.dmSans(fontSize: 16, color: onSurface),
        bodyMedium:    GoogleFonts.dmSans(fontSize: 14, color: onSurface),
        bodySmall:     GoogleFonts.dmSans(fontSize: 12, color: textMuted),
        labelLarge:    GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
        labelSmall:    GoogleFonts.dmSans(fontSize: 11, color: textMuted),
      ),

      // ── Inputs ──────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: GoogleFonts.dmSans(color: textMuted),
        hintStyle:  GoogleFonts.dmSans(color: textMuted),
      ),

      // ── Buttons ─────────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // ── Cards ───────────────────────────────────────────────────────────────
        cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: divider),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── Bottom Nav ──────────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary);
          }
          return const IconThemeData(color: textMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: primary);
          }
          return GoogleFonts.dmSans(fontSize: 12, color: textMuted);
        }),
        elevation: 0,
        shadowColor: divider,
      ),

      // ── Chips ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHigh,
        labelStyle: GoogleFonts.dmSans(fontSize: 12, color: onSurface),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // ── FAB ─────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        shape: CircleBorder(),
      ),

      // ── SnackBar ────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurface,
        contentTextStyle: GoogleFonts.dmSans(color: background, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ── Bottom Sheet ────────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}