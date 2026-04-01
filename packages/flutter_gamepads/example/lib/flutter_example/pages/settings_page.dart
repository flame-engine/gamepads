import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController nameController = TextEditingController(
    text: 'Player One',
  );
  FocusNode volumeFocusNode = FocusNode();
  final volumeHasFocus = ValueNotifier<bool>(false);
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
    volumeFocusNode.dispose();
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
          GamepadInterceptor(
            onBeforeIntent: (activator, intent) {
              // The Slider widget does not itself support any public Intent to
              // control it.
              //
              // So instead we intercept that GamepadControl is about to emit a
              // ScrollIntent and implement changing the Slider value ourself.
              if (intent is ScrollIntent) {
                if (intent.direction == AxisDirection.right) {
                  setState(() => volume = min(100, volume + 10));
                } else if (intent.direction == AxisDirection.left) {
                  setState(() => volume = max(0, volume - 10));
                }
                return false;
              }
              return true;
            },
            child: Slider.adaptive(
              focusNode: volumeFocusNode,
              max: 100,
              divisions: 10,
              label: 'Volume: ${volume.round()}',
              value: volume,
              onChanged: (value) => setState(() => volume = value),
            ),
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: Theme.of(context).filledButtonTheme.style!.copyWith(
                    backgroundColor: WidgetStatePropertyAll(Colors.grey[600]),
                  ),
                  onPressed: onReset,
                  child: const Text('Reset settings'),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: FilledButton(
                  onPressed: () => onSave(context),
                  child: const Text('Save settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void onReset() {
    setState(() {
      nameController.text = 'Player One';
      volume = 50;
      selectedGenre = 'Adventure';
      vibrationEnabled = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings reset')),
    );
  }

  void onSave(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Saved ${nameController.text} / $selectedGenre / ${volume.round()}',
        ),
      ),
    );
  }
}
