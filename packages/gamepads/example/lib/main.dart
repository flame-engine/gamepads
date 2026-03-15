import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';

void main() {
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

/// Wraps either a normalized event or a raw event that could not be
/// normalized.
class _EventEntry {
  final NormalizedGamepadEvent? normalized;
  final GamepadEvent raw;

  _EventEntry({required this.raw, this.normalized});
}

class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription<GamepadEvent>? _subscription;
  late final GamepadNormalizer _normalizer;

  List<GamepadController> _gamepads = [];
  List<_EventEntry> _lastEvents = [];
  bool loading = false;

  Future<void> _listGamepads() async {
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
    _normalizer = GamepadNormalizer();
    _subscription = Gamepads.events.listen((event) {
      final normalized = _normalizer.normalize(event);
      setState(() {
        final newEntries = <_EventEntry>[
          if (normalized.isEmpty)
            _EventEntry(raw: event)
          else
            for (final normalizedEvent in normalized)
              _EventEntry(
                normalized: normalizedEvent,
                raw: event,
              ),
          ..._lastEvents,
        ];
        if (newEntries.length > 8) {
          newEntries.removeRange(8, newEntries.length);
        }
        _lastEvents = newEntries;
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
                'Events:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._lastEvents.map(_buildEventTile),
              TextButton(
                onPressed: _clear,
                child: const Text('Clear Events'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _listGamepads,
                child: const Text('List Gamepads'),
              ),
              const Text(
                'Gamepads:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (loading)
                const CircularProgressIndicator()
              else ...[
                for (final gamepad in _gamepads) ...[
                  Text(
                    '${gamepad.id} - ${gamepad.name}',
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventTile(_EventEntry entry) {
    final normalized = entry.normalized;
    final raw = entry.raw;

    if (normalized != null) {
      final label = normalized.button != null
          ? '${normalized.button} = '
              '${normalized.value}'
          : '${normalized.axis} = '
              '${normalized.value.toStringAsFixed(2)}';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '$label  (raw: ${raw.key} ${raw.value})',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '[unmapped] ${raw.type.name}: '
        '${raw.key} = ${raw.value}',
        style: const TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
