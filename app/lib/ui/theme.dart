import 'package:material_ui/material_ui.dart';

/// Farben des Übungsplaners: Signalrot und Gelb.
abstract final class AppColors {
  static const red = Color(0xFFC8102E);
  static const yellow = Color(0xFFFFCC00);
  static const ok = Color(0xFF1F7A45);
  static const warn = Color(0xFFA85D00);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.red,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  ).copyWith(
    primary: dark ? const Color(0xFFFF5A6E) : AppColors.red,
    onPrimary: dark ? const Color(0xFF2A0007) : Colors.white,
    tertiary: AppColors.yellow,
    onTertiary: const Color(0xFF2A2200),
    tertiaryContainer: dark ? const Color(0xFF3F3510) : const Color(0xFFFFF5CC),
    onTertiaryContainer: dark ? const Color(0xFFFFF5CC) : const Color(0xFF2A2200),
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness);
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF171312) : const Color(0xFFF7F4F2),
    cardTheme: CardThemeData(
      color: dark ? const Color(0xFF221C1B) : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? const Color(0xFF221C1B) : Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      side: BorderSide.none,
    ),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    textTheme: base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}
