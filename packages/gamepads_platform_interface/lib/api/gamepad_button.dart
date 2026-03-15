/// Standard gamepad buttons modeled on the Xbox/standard gamepad layout.
///
/// This enum provides a platform-independent way to identify gamepad buttons.
/// The layout follows the convention used by Xbox controllers, which iOS,
/// Android, Web "standard" mapping, and SDL all converge on.
enum GamepadButton {
  /// The bottom face button (A on Xbox, Cross on PlayStation).
  a,

  /// The right face button (B on Xbox, Circle on PlayStation).
  b,

  /// The left face button (X on Xbox, Square on PlayStation).
  x,

  /// The top face button (Y on Xbox, Triangle on PlayStation).
  y,

  /// The left shoulder bumper (LB on Xbox, L1 on PlayStation).
  leftBumper,

  /// The right shoulder bumper (RB on Xbox, R1 on PlayStation).
  rightBumper,

  /// The left trigger as a digital button.
  leftTrigger,

  /// The right trigger as a digital button.
  rightTrigger,

  /// The back/select/share button.
  back,

  /// The start/menu button.
  start,

  /// The home/guide button.
  home,

  /// The left stick click (L3 on PlayStation).
  leftStick,

  /// The right stick click (R3 on PlayStation).
  rightStick,

  /// D-pad up.
  dpadUp,

  /// D-pad down.
  dpadDown,

  /// D-pad left.
  dpadLeft,

  /// D-pad right.
  dpadRight,
}
