import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';
import 'package:flutter_gamepads_example/pages/home_page.dart';
import 'package:flutter_gamepads_example/pages/settings_page.dart';
import 'package:flutter_gamepads_example/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GamepadControl(
      child: MaterialApp(
        theme: appTheme(),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/settings': (context) => const SettingsPage(),
        },
      ),
    );
  }
}
