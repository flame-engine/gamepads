enum KeyType { analog, button }

class GamepadEvent {
  final String gamepadId;
  final int timestamp;
  final KeyType type;
  final String key;
  final double value;

  GamepadEvent({
    required this.gamepadId,
    required this.timestamp,
    required this.type,
    required this.key,
    required this.value,
  });

  @override
  String toString() {
    return '[$gamepadId] $key: $value';
  }

  factory GamepadEvent.parse(Map<dynamic, dynamic> map) {
    final gamepadId = map['gamepadId'] as String;
    final timestamp = map['time'] as int;
    final type = KeyType.values.byName(map['type'] as String);
    final key = map['key'] as String;
    final value = map['value'] as double;

    return GamepadEvent(
      gamepadId: gamepadId,
      timestamp: timestamp,
      type: type,
      key: key,
      value: value,
    );
  }
}
