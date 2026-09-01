import 'package:flutter/material.dart';

/// Semantic colors for multi-colored buttons (not forced as brand).
class AppColors {
  AppColors._();

  static const Color blue = Color(0xFF1877F2);
  static const Color blueSoft = Color(0xFFE7F0FF);
  static const Color blueDark = Color(0xFF0D65D9);

  static const Color green = Color(0xFF009966); // brand green
  static const Color greenSoft = Color(0xFFE6F5F0);
  static const Color greenDark = Color(0xFF00754D);

  static const Color red = Color(0xFFE5484D);
  static const Color redSoft = Color(0xFFFDE8EC);
  static const Color redDark = Color(0xFFC53030);

  static const Color orange = Color(0xFFF5A623);
  static const Color orangeSoft = Color(0xFFFEF3C7);
  static const Color orangeDark = Color(0xFFE08E00);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleSoft = Color(0xFFF3E8FF);
  static const Color purpleDark = Color(0xFF7C3AED);

  static const Color teal = Color(0xFF14B8A6);
  static const Color tealSoft = Color(0xFFCCFBF1);
  static const Color tealDark = Color(0xFF0D9488);

  static const Color pink = Color(0xFFEC4899);
  static const Color pinkSoft = Color(0xFFFCE7F3);
  static const Color pinkDark = Color(0xFFDB2777);

  static const Color indigo = Color(0xFF6366F1);
  static const Color indigoSoft = Color(0xFFE0E7FF);
  static const Color indigoDark = Color(0xFF4F46E5);

  static const Color slate = Color(0xFF64748B);
  static const Color slateSoft = Color(0xFFF1F5F9);

  static Color softOf(Color c) {
    if (c == blue || c == blueDark) return blueSoft;
    if (c == green || c == greenDark) return greenSoft;
    if (c == red || c == redDark) return redSoft;
    if (c == orange || c == orangeDark) return orangeSoft;
    if (c == purple || c == purpleDark) return purpleSoft;
    if (c == teal || c == tealDark) return tealSoft;
    if (c == pink || c == pinkDark) return pinkSoft;
    if (c == indigo || c == indigoDark) return indigoSoft;
    return c.withOpacity(0.12);
  }
}

ButtonStyle appButtonStyle({
  required Color color,
  Color foreground = Colors.white,
  EdgeInsetsGeometry padding =
      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  double radius = 12,
  Size minimumSize = const Size(0, 48),
}) {
  return ElevatedButton.styleFrom(
    backgroundColor: color,
    foregroundColor: foreground,
    disabledBackgroundColor: color.withOpacity(0.4),
    disabledForegroundColor: Colors.white70,
    elevation: 0,
    padding: padding,
    minimumSize: minimumSize,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
  );
}

/// Hardware store theme — fresh-herb green primary + warm amber accent.
class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF009966);
  static const Color primaryDark = Color(0xFF00754D);
  static const Color primaryLight = Color(0xFF3DC08D);
  static const Color accentColor = Color(0xFFFF8A3D);
  static const Color accentDark = Color(0xFFE86A1C);

  static const Color successColor = Color(0xFF00A876);
  static const Color errorColor = Color(0xFFE5484D);
  static const Color warningColor = Color(0xFFF5A623);
  static const Color infoColor = Color(0xFF2E90E5);

  static const Color _lightBg = Color(0xFFF6F9F7);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFE6EAE8);

  static const Color _darkBg = Color(0xFF101613);
  static const Color _darkSurface = Color(0xFF1A2420);
  static const Color _darkSurfaceAlt = Color(0xFF212D28);
  static const Color _darkBorder = Color(0xFF2A3530);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00B37A), Color(0xFF00754D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFA35C), Color(0xFFE86A1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sidebarGradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF3FAF6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sidebarGradientDark = LinearGradient(
    colors: [Color(0xFF1A2420), Color(0xFF141D19)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient cardGlowGradient(bool isDark) => LinearGradient(
        colors: isDark
            ? [const Color(0xFF1F2E27), const Color(0xFF16211C)]
            : [const Color(0xFFEFFAF5), const Color(0xFFFFFFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static ThemeData lightTheme = _base(
    brightness: Brightness.light,
    scaffoldBg: _lightBg,
    surface: _lightSurface,
    border: _lightBorder,
    appBarBg: _lightSurface,
    appBarFg: const Color(0xFF14201B),
    textPrimary: const Color(0xFF14201B),
    textSecondary: const Color(0xFF5B6B64),
  );

  static ThemeData darkTheme = _base(
    brightness: Brightness.dark,
    scaffoldBg: _darkBg,
    surface: _darkSurface,
    border: _darkBorder,
    appBarBg: _darkSurface,
    appBarFg: Colors.white,
    textPrimary: const Color(0xFFEAF3EF),
    textSecondary: const Color(0xFF9DB0A8),
    surfaceAlt: _darkSurfaceAlt,
  );

  static ThemeData _base({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surface,
    required Color border,
    required Color appBarBg,
    required Color appBarFg,
    required Color textPrimary,
    required Color textSecondary,
    Color? surfaceAlt,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      splashFactory: InkRipple.splashFactory,
      canvasColor: surface,
      hoverColor: primaryColor.withOpacity(0.06),
      splashColor: primaryColor.withOpacity(0.12),
      highlightColor: primaryColor.withOpacity(0.06),
      textTheme: TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w800, color: textPrimary),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: textPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        labelLarge: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: appBarFg),
        actionsIconTheme: IconThemeData(color: appBarFg),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceAlt ?? surface : const Color(0xFFFAFCFB),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.8)),
        labelStyle: TextStyle(color: textSecondary),
        floatingLabelStyle:
            const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: errorColor, width: 1.4),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: appButtonStyle(color: primaryColor),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.4),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      iconTheme: IconThemeData(color: textSecondary),
      dividerColor: border,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        contentTextStyle:
            TextStyle(fontSize: 14, color: textSecondary, height: 1.4),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        textStyle: TextStyle(color: textPrimary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? surfaceAlt ?? surface : const Color(0xFFF0F4F2),
        selectedColor: primaryColor.withOpacity(isDark ? 0.28 : 0.16),
        disabledColor: isDark ? surface : const Color(0xFFF0F4F2),
        labelStyle: TextStyle(
            color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
        secondaryLabelStyle: TextStyle(
            color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        checkmarkColor: primaryColor,
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primaryColor : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? primaryColor.withOpacity(0.5)
              : null,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primaryColor : null,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primaryColor : null,
        ),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: primaryColor),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? Colors.white : const Color(0xFF14201B),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: isDark ? const Color(0xFF14201B) : Colors.white,
          fontSize: 12,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.15),
        ),
        radius: const Radius.circular(8),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        selectedColor: primaryColor,
        selectedTileColor: primaryColor.withOpacity(isDark ? 0.18 : 0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
