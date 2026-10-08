import 'package:flutter/widgets.dart';
import 'package:flutter_gamepads/flutter_gamepads.dart';

class GamepadShortcuts {
  /// A shortcuts configuration for [GamepadControl] using sequential focus
  /// intents.
  static const Map<GamepadActivator, Intent> sequentialTraversal = {
    GamepadActivatorButton.a(): ActivateIntent(),
    GamepadActivatorButton.b(): DismissIntent(),
    GamepadActivatorButton.dpadUp(): PreviousFocusIntent(),
    GamepadActivatorButton.dpadLeft(): PreviousFocusIntent(),
    GamepadActivatorButton.dpadDown(): NextFocusIntent(),
    GamepadActivatorButton.dpadRight(): NextFocusIntent(),
    GamepadActivatorAxis.rightStickUp(): ScrollIntent(
      direction: AxisDirection.up,
    ),
    GamepadActivatorAxis.rightStickLeft(): ScrollIntent(
      direction: AxisDirection.left,
    ),
    GamepadActivatorAxis.rightStickDown(): ScrollIntent(
      direction: AxisDirection.down,
    ),
    GamepadActivatorAxis.rightStickRight(): ScrollIntent(
      direction: AxisDirection.right,
    ),
  };

  /// A shortcuts configuration for [GamepadControl] using directional focus
  /// intents.
  static const Map<GamepadActivator, Intent> directionalTraversal = {
    GamepadActivatorButton.a(): ActivateIntent(),
    GamepadActivatorButton.b(): DismissIntent(),
    GamepadActivatorButton.dpadUp(): DirectionalFocusIntent(
      TraversalDirection.up,
    ),
    GamepadActivatorButton.dpadLeft(): DirectionalFocusIntent(
      TraversalDirection.left,
    ),
    GamepadActivatorButton.dpadDown(): DirectionalFocusIntent(
      TraversalDirection.down,
    ),
    GamepadActivatorButton.dpadRight(): DirectionalFocusIntent(
      TraversalDirection.right,
    ),
    GamepadActivatorAxis.rightStickUp(): ScrollIntent(
      direction: AxisDirection.up,
    ),
    GamepadActivatorAxis.rightStickLeft(): ScrollIntent(
      direction: AxisDirection.left,
    ),
    GamepadActivatorAxis.rightStickDown(): ScrollIntent(
      direction: AxisDirection.down,
    ),
    GamepadActivatorAxis.rightStickRight(): ScrollIntent(
      direction: AxisDirection.right,
    ),
  };
}
