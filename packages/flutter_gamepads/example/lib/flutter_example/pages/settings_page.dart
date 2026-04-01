import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';
import 'package:flutter_gamepads_example/flutter_example/pages/slider_with_gamepad_support.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController nameController = TextEditingController(
    text: 'Player One',
  );
  double volume = 50;
  String selectedGenre = 'Adventure';
  bool vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Player name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 20),
          // This one Wraps a Slider with GamepadInterceptor to add gamepad
          // support to the default Slider widget
          SliderWithGamepadSupport(
            value: volume,
            max: 100,
            divisions: 5,
            label: 'Volume: ${volume.round()}',
            onChanged: (value) {
              setState(() {
                volume = value;
              });
            },
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text('Genre'),
            trailing: SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                initialValue: selectedGenre,
                items:
                    [
                          'Adventure',
                          'Simulation',
                          'RPG',
                        ]
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedGenre = value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Vibration'),
            value: vibrationEnabled,
            onChanged: (value) => setState(() => vibrationEnabled = value),
          ),
        ],
      ),
    );
  }
}
