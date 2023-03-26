class GamepadEvent {
  final String gamepadId;
  final String value;

  GamepadEvent({
    required this.gamepadId,
    required this.value,
  });

  factory GamepadEvent.parse(Map<dynamic, dynamic> map) {
    final gamepadId = map['gamepadId'] as String;
    final value = map['value'] as String;

    return GamepadEvent(gamepadId: gamepadId, value: value);
  }
}
