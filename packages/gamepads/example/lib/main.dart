import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';

void main() {
  Gamepads.normalizer = GamepadNormalizer();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gamepads Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription<NormalizedGamepadEvent>? _subscription;

  List<GamepadController> _gamepads = [];
  List<NormalizedGamepadEvent> _lastEvents = [];
  bool loading = false;

  Future<void> _getValue() async {
    setState(() => loading = true);
    final response = await Gamepads.list();
    setState(() {
      _gamepads = response;
      loading = false;
    });
  }

  void _clear() {
    setState(() => _lastEvents = []);
  }

  @override
  void initState() {
    super.initState();
    _subscription = Gamepads.normalizedEvents.listen((event) {
      setState(() {
        final newEvents = [
          event,
          ..._lastEvents,
        ];
        if (newEvents.length > 5) {
          newEvents.removeRange(5, newEvents.length);
        }
        _lastEvents = newEvents;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamepads Example'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Normalized Events:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._lastEvents.map(_buildEventTile),
              TextButton(
                onPressed: _clear,
                child: const Text('Clear Events'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _getValue,
                child: const Text('List Gamepads'),
              ),
              const Text(
                'Gamepads:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (loading)
                const CircularProgressIndicator()
              else ...[
                for (final gamepad in _gamepads) ...[
                  Text('${gamepad.id} - ${gamepad.name}'),
                  Text(
                    '  Analog inputs: '
                    '${gamepad.state.analogInputs}',
                  ),
                  Text(
                    '  Button inputs: '
                    '${gamepad.state.buttonInputs}',
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventTile(NormalizedGamepadEvent event) {
    final normalized = event.button != null
        ? '${event.button} = ${event.value}'
        : '${event.axis} = ${event.value.toStringAsFixed(2)}';
    final raw = event.rawEvent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$normalized  (raw: ${raw.key} ${raw.value})',
      ),
    );
  }
}
