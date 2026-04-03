import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gamepads_example/flame_example/components/power_up.dart';
import 'package:flutter_gamepads_example/flame_example/game.dart';
import 'package:flutter_gamepads_example/flame_example/state/game_state.dart';
import 'package:gamepads/gamepads.dart';

class SpaceShip extends SpriteComponent
    with KeyboardHandler, CollisionCallbacks, HasGameReference<MyGame> {
  /// inputX refer to request to change ship rotation
  double inputX = 0;

  /// inputY refer to request to accelerate/bake the ship
  double inputY = 0;

  /// Velocity in world coordinates
  Vector2 velocity = Vector2.zero();
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
    super.update(dt);

    // Get installed upgrades
    final hasTurnRail = game.gameState.installedUpgrades.value.contains(
      SpaceshipUpgrades.turnRail,
    );
    final hasAutoBrake = game.gameState.installedUpgrades.value.contains(
      SpaceshipUpgrades.autoBrake,
    );

    // Update angle based on user input (inputX)
    angle += inputX * dt * rotationVelocity;

    // Get fraction of travel in angle direction in x and y world coordinates.
    // (velocity independent base-fraction)
    final angleX = cos(angle - pi / 2);
    final angleY = sin(angle - pi / 2);

    // Compute change in velocity based on user input (inputY)
    final ddy = inputY > 0 ? accel : decel;
    if (hasTurnRail) {
      var dy = velocity.length;
      dy = max(0, dy + inputY * dt * ddy);
      velocity.x = angleX * dy;
      velocity.y = angleY * dy;
    } else {
      velocity.x += angleX * dt * max(inputY, 0) * ddy;
      velocity.y += angleY * dt * max(inputY, 0) * ddy;
    }

    // Auto brake?
    if (hasAutoBrake && inputY < 0.01 && velocity.length >= 0.001) {
      velocity.clampLength(0, max(0, velocity.length - dt * autoBrakeDecel));
    }

    // Update spaceship position
    if (velocity.length > 0.001) {
      position.x += velocity.x * dt;
      position.y += velocity.y * dt;
    }
  }

  // Keyboard input support
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

  /// Listener for Gamepad events. This process events directly from
  /// underlying gamepads plugin, and not via GamepadControl.
  ///
  /// Whenever a dialog is opened, the flame game engine is paused causing
  /// no update() to occur for the spaceship.
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

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is PowerUp) {
      game.world.remove(other);
      game.gameState.powerUps.value += 1;
    }

    super.onCollision(intersectionPoints, other);
  }
}
