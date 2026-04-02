import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';
import 'package:flutter_gamepads_example/flutter_example/pages/game_page.dart';
import 'package:flutter_gamepads_example/flutter_example/pages/home_page.dart';
import 'package:flutter_gamepads_example/flutter_example/pages/settings_page.dart';
import 'package:flutter_gamepads_example/flutter_example/theme.dart';

void main() {
  runApp(const MyFlutterApp());
}

class MyFlutterApp extends StatelessWidget {
  /// Callback provided by the Example chooser that allow the
  /// example to signal that user wants to exit the example.
  final void Function()? exitApp;

  const MyFlutterApp({this.exitApp, super.key});

  @override
  Widget build(BuildContext context) {
    // The GamepadControl widget here in the root provides user ability
    // to control the app with their gamepad. At some places through
    // out flutter_example, there is GamepadInterceptor widgets that
    // intercepts Gamepad input before GamepadControl invokes the mapped
    // intent for the Gamepad input.
    return GamepadControl(
      child: MaterialApp(
        theme: appTheme(),
        initialRoute: '/',
        routes: {
          '/': (context) => HomePage(exitApp: exitApp),
          '/settings': (context) => const SettingsPage(),
          '/game': (context) => const GamePage(),
        },
      ),
    );
  }
}
