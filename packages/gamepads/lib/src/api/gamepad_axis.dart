/// Standard gamepad axes modeled on the Xbox/standard gamepad layout.
///
/// Stick axes are normalized to -1.0 to 1.0 (Left/Down = -1, Right/Up = +1).
/// Trigger axes are normalized to 0.0 to 1.0 (Released = 0, Fully pressed = 1).
enum GamepadAxis {
  /// Left stick horizontal axis. -1.0 (left) to 1.0 (right).
  leftStickX,

  /// Left stick vertical axis. -1.0 (down) to 1.0 (up).
  leftStickY,

  /// Right stick horizontal axis. -1.0 (left) to 1.0 (right).
  rightStickX,

  /// Right stick vertical axis. -1.0 (down) to 1.0 (up).
  rightStickY,

  /// Left trigger analog axis. 0.0 (released) to 1.0 (fully pressed).
  leftTrigger,

  /// Right trigger analog axis. 0.0 (released) to 1.0 (fully pressed).
  rightTrigger,
}
