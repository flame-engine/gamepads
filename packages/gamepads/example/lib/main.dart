import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final List<String> _eventLog = [];
  final Map<String, String> _gamepadNames = {};
  bool loading = false;

  Future<void> _listGamepads() async {
    setState(() => loading = true);
    final response = await Gamepads.list();
    for (final gamepad in response) {
      _gamepadNames[gamepad.id] = gamepad.name;
    }
    setState(() {
      _gamepads = response;
      loading = false;
    });
  }

  void _clear() {
    setState(() {
      _lastEvents = [];
      _eventLog.clear();
    });
  }

  Future<void> _shareLog() async {
    if (_eventLog.isEmpty) {
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/gamepad_log.txt');
    await file.writeAsString(_eventLog.join('\n'));
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  void initState() {
    super.initState();
    _normalizer = GamepadNormalizer();
    _subscription = Gamepads.events.listen((event) {
      if (!_gamepadNames.containsKey(event.gamepadId)) {
        _listGamepads();
      }
      final normalized = _normalizer.normalize(event);
      final timestamp = DateTime.now().toIso8601String();
      final name = _gamepadNames[event.gamepadId];
      final device =
          name ??
          'vendor:${event.vendorId ?? "?"} '
              'product:${event.productId ?? "?"}';
      if (normalized.isEmpty) {
        _eventLog.add(
          '$timestamp [$device] [unmapped] ${event.type.name}: '
          '${event.key} = ${event.value}',
        );
      } else {
        for (final n in normalized) {
          final label = n.button != null
              ? '${n.button} = ${n.value}'
              : '${n.axis} = ${n.value.toStringAsFixed(2)}';
          _eventLog.add(
            '$timestamp [$device] $label '
            '(raw: ${event.key} ${event.value})',
          );
        }
      }
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
              TextButton(
                onPressed: _eventLog.isEmpty ? null : _shareLog,
                child: const Text('Share Log'),
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
