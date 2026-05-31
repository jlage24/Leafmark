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
          minimumSize: const Size(64, 48),
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

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    const darkBackground = Color(0xFF050705);      // near-black forest
    const darkSurface = Color(0xFF0D120D);         // deep leaf surface
    const darkSurfaceHigh = Color(0xFF171F16);     // elevated cards
    const darkSurfaceSoft = Color(0xFF20291D);     // chips / selected states
    const darkOnSurface = Color(0xFFF4EFE6);       // warm ivory
    const darkMuted = Color(0xFFB9AD9C);           // muted parchment
    const darkDivider = Color(0xFF2A3327);         // subtle moss divider

    const darkPrimary = Color(0xFFA8C99A);         // muted sage
    const darkOnPrimary = Color(0xFF10200D);
    const darkSecondary = Color(0xFFE0A06F);       // soft terracotta
    const darkOnSecondary = Color(0xFF2A1205);
    const darkAccent = Color(0xFFD8B45A);          // antique gold
    const darkError = Color(0xFFFFB4AB);
    const darkOnError = Color(0xFF690005);

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,

      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        secondary: darkSecondary,
        onSecondary: darkOnSecondary,
        tertiary: darkAccent,
        onTertiary: Color(0xFF261A00),
        surface: darkSurface,
        onSurface: darkOnSurface,
        surfaceContainerHighest: darkSurfaceHigh,
        outline: darkDivider,
        outlineVariant: Color(0xFF20281E),
        error: darkError,
        onError: darkOnError,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: darkOnSurface,
        ),
        iconTheme: const IconThemeData(color: darkOnSurface),
      ),

      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.dmSerifDisplay(color: darkOnSurface),
        displayMedium: GoogleFonts.dmSerifDisplay(color: darkOnSurface),
        displaySmall: GoogleFonts.dmSerifDisplay(color: darkOnSurface),
        headlineLarge: GoogleFonts.dmSerifDisplay(color: darkOnSurface),
        headlineMedium: GoogleFonts.dmSerifDisplay(color: darkOnSurface),
        headlineSmall: GoogleFonts.dmSerifDisplay(color: darkOnSurface),
        titleLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 20,
          color: darkOnSurface,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
        ),
        titleSmall: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          color: darkOnSurface,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          color: darkOnSurface,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          color: darkMuted,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11,
          color: darkMuted,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkPrimary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkError, width: 1.4),
        ),
        labelStyle: GoogleFonts.dmSans(color: darkMuted),
        hintStyle: GoogleFonts.dmSans(color: darkMuted),
        prefixIconColor: darkMuted,
        suffixIconColor: darkMuted,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(color: darkDivider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: darkDivider),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: darkSurfaceSoft,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkPrimary);
          }
          return const IconThemeData(color: darkMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: darkPrimary,
            );
          }
          return GoogleFonts.dmSans(fontSize: 12, color: darkMuted);
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceHigh,
        selectedColor: darkSurfaceSoft,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
        ),
        secondaryLabelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: darkPrimary,
        ),
        side: const BorderSide(color: darkDivider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
        space: 1,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: darkOnPrimary,
        elevation: 2,
        shape: CircleBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceHigh,
        contentTextStyle: GoogleFonts.dmSans(
          color: darkOnSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.dmSans(
          color: darkOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: GoogleFonts.dmSans(
          color: darkMuted,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimary;
          return darkMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkPrimary.withValues(alpha: 0.32);
          }
          return darkDivider;
        }),
      ),
    );
  }
}