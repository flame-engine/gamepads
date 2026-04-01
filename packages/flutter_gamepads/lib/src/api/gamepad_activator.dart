import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';

@immutable
class GamepadActivator {
  const GamepadActivator();
}

class GamepadActivatorButton extends GamepadActivator {
  final GamepadButton button;
  const GamepadActivatorButton({required this.button});

  /// GamepadActivator for [GamepadButton.a]
  const GamepadActivatorButton.a() : button = GamepadButton.a;

  /// GamepadActivator for [GamepadButton.b]
  const GamepadActivatorButton.b() : button = GamepadButton.b;

  /// GamepadActivator for [GamepadButton.x]
  const GamepadActivatorButton.x() : button = GamepadButton.x;

  /// GamepadActivator for [GamepadButton.y]
  const GamepadActivatorButton.y() : button = GamepadButton.y;

  /// GamepadActivator for [GamepadButton.leftBumper]
  const GamepadActivatorButton.leftBumper() : button = GamepadButton.leftBumper;

  /// GamepadActivator for [GamepadButton.rightBumper]
  const GamepadActivatorButton.rightBumper()
    : button = GamepadButton.rightBumper;

  /// GamepadActivator for [GamepadButton.leftTrigger]
  const GamepadActivatorButton.leftTrigger()
    : button = GamepadButton.leftTrigger;

  /// GamepadActivator for [GamepadButton.rightTrigger]
  const GamepadActivatorButton.rightTrigger()
    : button = GamepadButton.rightTrigger;

  /// GamepadActivator for [GamepadButton.back]
  const GamepadActivatorButton.back() : button = GamepadButton.back;

  /// GamepadActivator for [GamepadButton.start]
  const GamepadActivatorButton.start() : button = GamepadButton.start;

  /// GamepadActivator for [GamepadButton.home]
  const GamepadActivatorButton.home() : button = GamepadButton.home;

  /// GamepadActivator for [GamepadButton.leftStick]
  const GamepadActivatorButton.leftStick() : button = GamepadButton.leftStick;

  /// GamepadActivator for [GamepadButton.rightStick]
  const GamepadActivatorButton.rightStick() : button = GamepadButton.rightStick;

  /// GamepadActivator for [GamepadButton.dpadUp]
  const GamepadActivatorButton.dpadUp() : button = GamepadButton.dpadUp;

  /// GamepadActivator for [GamepadButton.dpadDown]
  const GamepadActivatorButton.dpadDown() : button = GamepadButton.dpadDown;

  /// GamepadActivator for [GamepadButton.dpadLeft]
  const GamepadActivatorButton.dpadLeft() : button = GamepadButton.dpadLeft;

  /// GamepadActivator for [GamepadButton.dpadRight]
  const GamepadActivatorButton.dpadRight() : button = GamepadButton.dpadRight;
}

class GamepadActivatorAxis extends GamepadActivator {
  final GamepadAxis axis;
  final double minThreshold;
  const GamepadActivatorAxis({required this.axis, required this.minThreshold});

  const GamepadActivatorAxis.leftStickUp()
    : axis = GamepadAxis.leftStickY,
      minThreshold = _threshold;
  const GamepadActivatorAxis.leftStickDown()
    : axis = GamepadAxis.leftStickY,
      minThreshold = -_threshold;
  const GamepadActivatorAxis.leftStickLeft()
    : axis = GamepadAxis.leftStickX,
      minThreshold = -_threshold;
  const GamepadActivatorAxis.leftStickRight()
    : axis = GamepadAxis.leftStickX,
      minThreshold = _threshold;
  const GamepadActivatorAxis.rightStickUp()
    : axis = GamepadAxis.rightStickY,
      minThreshold = _threshold;
  const GamepadActivatorAxis.rightStickDown()
    : axis = GamepadAxis.rightStickY,
      minThreshold = -_threshold;
  const GamepadActivatorAxis.rightStickLeft()
    : axis = GamepadAxis.rightStickX,
      minThreshold = -_threshold;
  const GamepadActivatorAxis.rightStickRight()
    : axis = GamepadAxis.rightStickX,
      minThreshold = _threshold;
  const GamepadActivatorAxis.leftTrigger()
    : axis = GamepadAxis.leftTrigger,
      minThreshold = _threshold;
  const GamepadActivatorAxis.rightTrigger()
    : axis = GamepadAxis.rightTrigger,
      minThreshold = _threshold;
}

const _threshold = 0.3;
