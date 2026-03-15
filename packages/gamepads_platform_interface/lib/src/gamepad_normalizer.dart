import 'dart:async';

import 'package:gamepads_platform_interface/api/gamepad_event.dart';
import 'package:gamepads_platform_interface/api/normalized_gamepad_event.dart';
import 'package:gamepads_platform_interface/src/mappings/android_mapping.dart';
import 'package:gamepads_platform_interface/src/mappings/ios_mapping.dart';
import 'package:gamepads_platform_interface/src/mappings/linux_mapping.dart';
import 'package:gamepads_platform_interface/src/mappings/macos_mapping.dart';
import 'package:gamepads_platform_interface/src/mappings/platform_mapping.dart';
import 'package:gamepads_platform_interface/src/mappings/web_standard_mapping.dart';
import 'package:gamepads_platform_interface/src/mappings/windows_mapping.dart';

/// The platform this normalizer should use for mapping.
enum GamepadPlatform {
  android,
  ios,
  macos,
  linux,
  windows,
  web,
}

/// Transforms raw [GamepadEvent]s into [NormalizedGamepadEvent]s using
/// platform-specific mappings.
///
/// Usage:
/// ```dart
/// final normalizer = GamepadNormalizer(platform: GamepadPlatform.linux);
/// final normalized = normalizer.normalize(rawEvent);
/// ```
///
/// For stream transformation:
/// ```dart
/// final normalizedStream = rawStream
///     .transform(normalizer.transformer);
/// ```
class GamepadNormalizer {
  final PlatformMapping _mapping;
  final Map<String, PlatformMapping> _deviceMappings = {};

  GamepadNormalizer({required GamepadPlatform platform})
      : _mapping = _createMapping(platform);

  /// Creates a normalizer with a custom mapping (useful for testing).
  GamepadNormalizer.withMapping(this._mapping);

  static PlatformMapping _createMapping(GamepadPlatform platform) {
    switch (platform) {
      case GamepadPlatform.android:
        return AndroidMapping();
      case GamepadPlatform.ios:
        return IosMapping();
      case GamepadPlatform.macos:
        return MacosMapping();
      case GamepadPlatform.linux:
        return LinuxMapping();
      case GamepadPlatform.windows:
        return WindowsMapping();
      case GamepadPlatform.web:
        return WebStandardMapping();
    }
  }

  /// Sets the device info for a specific gamepad, allowing device-specific
  /// mappings to be selected (relevant for Linux and Windows).
  void setDeviceInfo(
    String gamepadId, {
    required int vendorId,
    required int productId,
  }) {
    _deviceMappings[gamepadId] = _mapping.forDevice(
      vendorId: vendorId,
      productId: productId,
    );
  }

  PlatformMapping _mappingFor(String gamepadId) {
    return _deviceMappings[gamepadId] ?? _mapping;
  }

  /// Normalizes a single [GamepadEvent].
  ///
  /// Returns a list of [NormalizedGamepadEvent]s. Most events produce a single
  /// normalized event, but d-pad axis events may produce multiple button events
  /// (e.g., dpadLeft pressed + dpadRight released).
  ///
  /// Returns an empty list if the event could not be normalized.
  List<NormalizedGamepadEvent> normalize(GamepadEvent event) {
    final mapping = _mappingFor(event.gamepadId);
    final results = <NormalizedGamepadEvent>[];

    switch (event.type) {
      case KeyType.button:
        final result = mapping.normalizeButton(event.key, event.value);
        if (result != null) {
          results.add(
            NormalizedGamepadEvent(
              gamepadId: event.gamepadId,
              timestamp: event.timestamp,
              button: result.button,
              value: result.value,
              rawEvent: event,
            ),
          );
        }

      case KeyType.analog:
        // First check if this is a recognized axis.
        final axisResult = mapping.normalizeAxis(event.key, event.value);
        if (axisResult != null) {
          results.add(
            NormalizedGamepadEvent(
              gamepadId: event.gamepadId,
              timestamp: event.timestamp,
              axis: axisResult.axis,
              value: axisResult.value,
              rawEvent: event,
            ),
          );
        }

        // Also check if this is a d-pad axis (produces button events).
        final dpadResults = mapping.normalizeDpadAxis(
          event.key,
          event.value,
        );
        for (final dpad in dpadResults) {
          results.add(
            NormalizedGamepadEvent(
              gamepadId: event.gamepadId,
              timestamp: event.timestamp,
              button: dpad.button,
              value: dpad.value,
              rawEvent: event,
            ),
          );
        }
    }

    return results;
  }

  /// A [StreamTransformer] that converts a stream of [GamepadEvent]s
  /// into a stream of [NormalizedGamepadEvent]s.
  StreamTransformer<GamepadEvent, NormalizedGamepadEvent> get transformer {
    return StreamTransformer<GamepadEvent, NormalizedGamepadEvent>.fromHandlers(
      handleData: (event, sink) {
        for (final normalized in normalize(event)) {
          sink.add(normalized);
        }
      },
    );
  }
}
