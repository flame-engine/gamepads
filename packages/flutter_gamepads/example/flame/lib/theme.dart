import 'package:flutter/material.dart';

ThemeData buildTheme() {
  return ThemeData.from(
    colorScheme: ColorScheme.dark(
      primary: Colors.orange[700]!,
      surface: Color.lerp(Colors.orange[900], Colors.grey[800], 0.7)!,
    ),
  ).copyWith(
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        /// Provide an expressive border color for focused buttons.
        shape: WidgetStateProperty.resolveWith((state) {
          return RoundedRectangleBorder(
            side: BorderSide(
              color: state.contains(WidgetState.focused)
                  ? Colors.lightGreenAccent
                  : Colors.transparent,
              width: 4,
            ),
            borderRadius: BorderRadiusGeometry.circular(
              state.contains(WidgetState.focused) ? 2 : 5,
            ),
          );
        }),
      ),
    ),
  );
}
