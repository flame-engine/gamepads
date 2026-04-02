import 'package:flutter/material.dart';

ThemeData appTheme() {
  final theme = ThemeData.from(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
  );
  const focusColor = Colors.orange;
  // A base border with highlight color for focused state.
  final focusBorder = WidgetStateBorderSide.resolveWith((state) {
    if (state.contains(WidgetState.focused)) {
      return const BorderSide(color: focusColor, width: 3);
    }
    return const BorderSide(color: Colors.transparent, width: 3);
  });
  // Apply the border style to different types of buttons used in the example
  // app
  return theme.copyWith(
    focusColor: focusColor,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.indigo[500]),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        side: focusBorder,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.indigo[500]),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        side: focusBorder,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.indigo[100]),
        foregroundColor: const WidgetStatePropertyAll(Colors.black),
        side: focusBorder,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: focusColor,
          width: 3,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[200],
    ),
  );
}
