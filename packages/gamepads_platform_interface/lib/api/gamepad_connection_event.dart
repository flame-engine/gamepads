/// Whether a gamepad became available or unavailable.
enum GamepadConnectionEventType {
  /// The gamepad was plugged in or paired and can now fire events.
  connected,

  /// The gamepad was unplugged or unpaired and will not fire any more events.
  disconnected,
}

/// Represents a gamepad controller being connected to or disconnected from
/// the device.
class GamepadConnectionEvent {
  /// The id of the gamepad controller that was connected or disconnected.
  ///
  /// It matches the id reported by `listGamepads` and the `gamepadId` of the
  /// events fired by that controller.
  final String gamepadId;

  /// A user-facing, platform-dependant name for the gamepad controller.
  final String name;

  /// Whether the gamepad was connected or disconnected.
  final GamepadConnectionEventType type;

  GamepadConnectionEvent({
    required this.gamepadId,
    required this.name,
    required this.type,
  });

  @override
  String toString() {
    return '[$gamepadId] $name: ${type.name}';
  }

  factory GamepadConnectionEvent.parse(Map<dynamic, dynamic> map) {
    final gamepadId = map['gamepadId'] as String;
    final name = map['name'] as String;
    final type = GamepadConnectionEventType.values.byName(
      map['type'] as String,
    );

    return GamepadConnectionEvent(
      gamepadId: gamepadId,
      name: name,
      type: type,
    );
  }
}
