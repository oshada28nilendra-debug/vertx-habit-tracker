import 'package:flutter/material.dart';

abstract final class FlowColors {
  static const charcoal = Color(0xFF242423);
  static const ivory = Color(0xFFF0E9E1);
  static const taupe = Color(0xFFB4A69D);
  static const ink = Color(0xFF272725);
}

final appThemeMode = ValueNotifier(ThemeMode.light);
ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final surface = dark ? const Color(0xFF333331) : FlowColors.ivory;
  final ink = dark ? FlowColors.ivory : FlowColors.ink;
  final scheme = ColorScheme.fromSeed(
          seedColor: FlowColors.charcoal, brightness: brightness)
      .copyWith(
    primary: ink,
    onPrimary: surface,
    surface: surface,
    onSurface: ink,
    secondary: FlowColors.taupe,
    onSecondary: FlowColors.ink,
    primaryContainer: dark ? const Color(0xFF55504B) : const Color(0xFFE1D8CF),
    onPrimaryContainer: ink,
    onSurfaceVariant: dark ? const Color(0xFFCEC6BD) : const Color(0xFF655E58),
    surfaceTint: Colors.transparent,
    outline: dark ? const Color(0xFFADA69D) : const Color(0xFF8B847D),
    outlineVariant: dark ? const Color(0xFF514E49) : const Color(0xFFD8CFC6),
  );
  final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Poppins',
      colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: FlowColors.charcoal,
    iconTheme: IconThemeData(color: ink),
    listTileTheme: ListTileThemeData(iconColor: ink, textColor: ink),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? surface : scheme.outline),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? ink
              : scheme.primaryContainer),
      trackOutlineColor: WidgetStatePropertyAll(scheme.outline),
    ),
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    dividerTheme: DividerThemeData(
        color: scheme.outlineVariant, thickness: 0.7, space: 1),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        height: 76,
        labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontFamily: 'Poppins', fontSize: 10, color: ink))),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: surface,
            elevation: 0,
            minimumSize: const Size(48, 52),
            textStyle: const TextStyle(
                fontFamily: 'Poppins', fontSize: 15, letterSpacing: 0.6),
            shape: const StadiumBorder())),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            minimumSize: const Size(48, 48),
            shape: const StadiumBorder())),
    chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.primaryContainer,
        selectedColor: ink,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: TextStyle(fontFamily: 'Poppins', color: ink, fontSize: 12)),
    inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: scheme.outline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: ink, width: 1.5))),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)))),
    dialogTheme: DialogThemeData(backgroundColor: surface),
    snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(fontFamily: 'Poppins', color: surface),
        behavior: SnackBarBehavior.floating),
  );
}
