import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter_gamepads_example/flame_example/components/power_up.dart';
import 'package:flutter_gamepads_example/flame_example/components/spaceship.dart';
import 'package:flutter_gamepads_example/flame_example/game.dart';

class MyWorld extends World
    with HasCollisionDetection, HasGameReference<MyGame> {
  static const worldSizeX = 1000.0;
  static const worldSizeY = 1000.0;
  @override
  FutureOr<void> onLoad() {
    final spaceShip = SpaceShip();

    addAll([
      spaceShip,
      ...List<PowerUp>.generate(
        10,
        (i) => PowerUp()
          ..position = Vector2(
            Random().nextDoubleBetween(-worldSizeX / 2, worldSizeX / 2),
            Random().nextDoubleBetween(-worldSizeX / 2, worldSizeY / 2),
          ),
      ),
    ]);

    game.camera.follow(spaceShip);

    return super.onLoad();
  }
}
