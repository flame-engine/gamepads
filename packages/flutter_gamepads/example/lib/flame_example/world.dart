import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gamepads_example/flame_example/game.dart';
import 'package:flutter_gamepads_example/flame_example/state/game_state.dart';
import 'package:gamepads/gamepads.dart';

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

class SpaceShip extends SpriteComponent
    with KeyboardHandler, CollisionCallbacks, HasGameReference<MyGame> {
  double inputX = 0;
  double inputY = 0;
  Vector2 velocity = Vector2.zero();
  double dy = 0;
  StreamSubscription? _subscription;

  static const rotationVelocity = 2.0;
  static const accel = 50.0;
  static const decel = 100.0;
  static const autoBrakeDecel = 25.0;
  static const gamepadDeadZone = 0.15;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('spaceship.png');
    anchor = Anchor.center;
    add(RectangleHitbox());
    _subscription = Gamepads.normalizedEvents.listen(onGamepadEvent);
    return super.onLoad();
  }

  @override
  void onRemove() {
    _subscription?.cancel();
    super.onRemove();
  }

  @override
  void update(double dt) {
    _basicUpdate(dt);
    super.update(dt);
  }

  void _basicUpdate(double dt) {
    bool hasTurnRail = game.gameState.installedUpgrades.value.contains(
      SpaceshipUpgrades.turnRail,
    );
    bool hasAutoBrake = game.gameState.installedUpgrades.value.contains(
      SpaceshipUpgrades.autoBrake,
    );

    angle += inputX * dt * rotationVelocity;

    final angleX = cos(angle - pi / 2);
    final angleY = sin(angle - pi / 2);

    final ddy = inputY > 0 ? accel : decel;

    if (hasTurnRail) {
      var dy = velocity.length;
      dy = max(0, dy + inputY * dt * (inputY > 0 ? accel : decel));
      velocity.x = angleX * dy;
      velocity.y = angleY * dy;
    } else {
      velocity.x += angleX * dt * max(inputY, 0) * ddy;
      velocity.y += angleY * dt * max(inputY, 0) * ddy;
    }

    if (hasAutoBrake && inputY < 0.01 && velocity.length >= 0.001) {
      velocity.clampLength(0, max(0, velocity.length - dt * autoBrakeDecel));
    }

    if (velocity.length > 0.001) {
      position.x += velocity.x * dt;
      position.y += velocity.y * dt;
    }
  }

  void _turnRailUpdate(double dt) {
    angle += inputX * dt * rotationVelocity;
    dy = max(0, dy + inputY * dt * (inputY > 0 ? accel : decel));

    if (dy.abs() > 0.001) {
      position.x += cos(angle - pi / 2) * dy * dt;
      position.y += sin(angle - pi / 2) * dy * dt;
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      inputX = -1;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      inputX = 1;
    } else {
      inputX = 0;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      inputY = 1;
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      inputY = -1;
    } else {
      inputY = 0;
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is PowerUp) {
      game.world.remove(other);
      game.gameState.powerUps.value += 1;
    }

    super.onCollision(intersectionPoints, other);
  }

  void onGamepadEvent(NormalizedGamepadEvent event) {
    if (event.axis == GamepadAxis.leftStickX) {
      inputX = event.value.abs() > gamepadDeadZone ? event.value : 0;
    }
    if (event.axis == GamepadAxis.rightTrigger) {
      inputY = event.value.abs() > gamepadDeadZone ? event.value : 0;
    }
    if (event.axis == GamepadAxis.leftTrigger) {
      inputY = event.value.abs() > gamepadDeadZone ? -event.value : 0;
    }
  }
}

class PowerUp extends SpriteComponent {
  Future<void> onLoad() async {
    sprite = await Sprite.load('power_up.png');
    anchor = Anchor.center;
    add(RectangleHitbox(collisionType: CollisionType.passive));
    return super.onLoad();
  }
}
