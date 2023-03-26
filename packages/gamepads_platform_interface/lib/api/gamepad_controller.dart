class GamepadController {
  final String id;
  GamepadController({required this.id});

  factory GamepadController.parse(Map<dynamic, dynamic> map) {
    final id = map['id']! as String;
    return GamepadController(id: id);
  }
}
