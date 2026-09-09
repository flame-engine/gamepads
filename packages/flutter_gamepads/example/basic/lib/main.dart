import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GamepadControl enables controlling the app with a gamepad.
    //
    // In many cases this is all you need. So start with just this
    // and test your app to see if there are cases that also need
    // to use a GamepadInterceptor to workaround issues.
    return const GamepadControl(
      child: MaterialApp(
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool switchValue = false;
  double sliderValue = 0.5;
  double slider2Value = 0.5;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Works with gamepads'),
          value: switchValue,
          onChanged: (value) => setState(() => switchValue = value),
        ),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Can be clicked with gamepad'),
        ),
        // This can be focused, but gamepad users cannot change the value
        // The solution is given below.
        Slider(
          value: sliderValue,
          label: 'Does not work with gamepads',
          onChanged: (value) => setState(() => sliderValue = value),
        ),
        // This slider can be operated with Gamepad due to the
        // compatibility layer provided via GamepadInterceptor.
        GamepadInterceptor(
          onBeforeIntent: (activator, intent) {
            if (intent is ScrollIntent) {
              if (intent.direction == AxisDirection.right) {
                setState(() => slider2Value = min(1.0, slider2Value + 0.1));
              } else if (intent.direction == AxisDirection.left) {
                setState(() => slider2Value = max(0.0, slider2Value - 0.1));
              }
              // Block actual emit of ScrollIntent
              return false;
            }
            // Allow other intents such as focus change to occur
            return true;
          },
          child: Slider(
            value: slider2Value,
            label: 'Works with gamepads',
            // This setState never occur by Gamepad input, but is
            // good to allow keyboard/mouse input as well.
            onChanged: (value) => setState(() => slider2Value = value),
          ),
        ),
      ],
    );
  }
}
