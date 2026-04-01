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
  final void Function()? exitApp;
  const MyFlutterApp({this.exitApp, super.key});

  @override
  Widget build(BuildContext context) {
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
