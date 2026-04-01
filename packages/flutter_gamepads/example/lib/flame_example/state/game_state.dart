
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

enum SpaceshipUpgrades {
  autoBrake,
  turnRail,
}

class GameState extends Component {
  final powerUps = ValueNotifier<int>(0);
  final installedUpgrades = ValueNotifier<Set<SpaceshipUpgrades>>({});
  final userPaused = ValueNotifier<bool>(false);
}