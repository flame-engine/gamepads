class GamepadController {
  final String id;
  final String name;

  GamepadController({
    required this.id,
    required this.name,
  });

  factory GamepadController.parse(Map<dynamic, dynamic> map) {
    final id = map['id'] as String;
    final name = map['name'] as String;
    return GamepadController(id: id, name: name);
  }
}
