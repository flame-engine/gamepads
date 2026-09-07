import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GamepadControl enables using the app with a gamepad.
    return const GamepadControl(child: MaterialApp(home: HomeScreen()));
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hello'),
              ),
            );
          },
          child: const Text('Button 1'),
        ),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('World'),
              ),
            );
          },
          child: const Text('Button 2'),
        ),
        const ElevatedButton(onPressed: null, child: Text('Disabled button')),
      ],
    );
  }
}
