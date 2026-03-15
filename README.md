# gamepads

<p align="center">
  A Flutter plugin to handle gamepad input across multiple platforms.
</p>

<p align="center">
  <a title="Pub" href="https://pub.dev/packages/gamepads">
    <img
      src="https://img.shields.io/pub/v/gamepads.svg?style=popout&include_prereleases"
      alt="Badge for latest release"
    />
  </a>
  <a title="Build Status" href="https://github.com/flame-engine/gamepads/actions?query=workflow%3Acicd+branch%3Amain">
    <img
      src="https://github.com/flame-engine/gamepads/workflows/cicd/badge.svg?branch=main"
      alt="Badge for build status"
    />
  </a>
  <a title="Discord" href="https://discord.gg/pxrBmy4">
    <img src="https://img.shields.io/discord/509714518008528896.svg" alt="Badge for Discord server"/>
  </a>
  <a title="Melos" href="https://github.com/invertase/melos">
    <img
      src="https://img.shields.io/badge/maintained%20with-melos-f700ff.svg"
      alt="Badge showing that Melos is used"
    />
  </a>
</p>

---

> **Note**: This plugin is still in beta. All APIs are subject to change. Any feedback is appreciated.

Gamepads is a Flutter plugin to handle gamepad (or joystick) input across multiple platforms.

It supports multiple simultaneously connected gamepads, and will automatically detect and listen to
new connections.


## Getting Started

The `list` method will list all currently connected gamepads:

```dart
  final gamepads = await Gamepads.list();
  // ...
```

This uses the data class `GamepadController`, which has an `id` and a user-facing `name`.

And the `events` stream will broadcast input events from all gamepads:

```dart
  Gamepads.events.listen((event) {
    // ...
  });
```

You can also listen to events only for a specific gamepad with `eventsByGamepad`.

Events are described by the data class `GamepadEvent`:

```dart
class GamepadEvent {
  /// The id of the gamepad controller that fired the event.
  final String gamepadId;

  /// The timestamp in which the event was fired, in milliseconds since epoch.
  final int timestamp;

  /// The [KeyType] of the key that was triggered.
  final KeyType type;

  /// A platform-dependant identifier for the key that was triggered.
  final String key;

  /// The current value of the key.
  final double value;

  // ...
}
```


## Normalized Events

By default, `GamepadEvent` exposes raw, platform-specific key strings and value ranges. The same
physical button produces different identifiers on each platform (e.g., the A button is `"0"` on
Linux, `"button-0"` on Windows, `"buttonA"` on iOS, `"KEYCODE_BUTTON_A"` on Android, and
`"button 0"` on Web). Value ranges also differ across platforms.

The normalization layer provides consistent button/axis identifiers and value ranges regardless of
platform or controller type. To use it, set up a `GamepadNormalizer` at app startup:

```dart
Gamepads.normalizer = GamepadNormalizer(
  platform: GamepadPlatform.android, // or .ios, .macos, .linux, .windows, .web
);
```

Then listen to `normalizedEvents` instead of `events`:

```dart
Gamepads.normalizedEvents.listen((event) {
  if (event.button == GamepadButton.a) {
    print('A button pressed!');
  }
  if (event.axis == GamepadAxis.leftStickX) {
    print('Left stick X: ${event.value}'); // -1.0 to 1.0
  }
});
```

### Standard Gamepad Model

Buttons and axes follow the Xbox/standard gamepad layout:

| Type            | Values                                        | Range                            |
|-----------------|-----------------------------------------------|----------------------------------|
| `GamepadButton` | `a`, `b`, `x`, `y`                            | 0.0 (released) or 1.0 (pressed)  |
| `GamepadButton` | `leftBumper`, `rightBumper`                   | 0.0 (released) or 1.0 (pressed)  |
| `GamepadButton` | `leftTrigger`, `rightTrigger`                 | 0.0 (released) or 1.0 (pressed)  |
| `GamepadButton` | `back`, `start`, `home`                       | 0.0 (released) or 1.0 (pressed)  |
| `GamepadButton` | `leftStick`, `rightStick`                     | 0.0 (released) or 1.0 (pressed)  |
| `GamepadButton` | `dpadUp`, `dpadDown`, `dpadLeft`, `dpadRight` | 0.0 (released) or 1.0 (pressed)  |
| `GamepadAxis`   | `leftStickX`, `leftStickY`                    | -1.0 to 1.0                      |
| `GamepadAxis`   | `rightStickX`, `rightStickY`                  | -1.0 to 1.0                      |
| `GamepadAxis`   | `leftTrigger`, `rightTrigger`                 | 0.0 to 1.0                       |

Stick conventions: Left/Down = -1, Right/Up = +1.

### Platform Mapping Tiers

**Tier 1 (no VID/PID needed):** iOS, macOS, Android, and Web provide semantic key names, so
normalization works out of the box.

**Tier 2 (VID/PID required):** Linux and Windows use raw numeric indices that vary by controller
hardware. For these platforms, the normalizer can use vendor/product IDs to select the correct
mapping from a built-in controller database (Xbox 360/One/Series, PS4/PS5, Nintendo Switch Pro).

For unknown controllers, the default behavior is best-effort mapping using an Xbox-like layout.
You can switch to strict mode (returns `null` for unrecognized inputs) by configuring the
normalizer accordingly.

### Normalized State

`GamepadController` also provides a `normalizedState` alongside the existing `state`, offering
convenient `isPressed(GamepadButton)` and `axisValue(GamepadAxis)` methods:

```dart
final controllers = await Gamepads.list();
final controller = controllers.first;
if (controller.normalizedState.isPressed(GamepadButton.a)) {
  // A is currently held
}
final stickX = controller.normalizedState.axisValue(GamepadAxis.leftStickX);
```

The original raw events are always preserved via `NormalizedGamepadEvent.rawEvent`, so you can
fall back to platform-specific handling when needed.


## Next Steps

As mentioned, this is still a WIP library. Not only APIs are expected to change if needed, but we
 plan to add more features, like:

- stream to listen for connecting/disconnecting gamepads
- get current state of a gamepad

If you are interested in helping, please reach out!
You can use GitHub or our [Discord server](https://discord.gg/pxrBmy4).


## Android Integration

The Android implementation requires the application's Activity to forward input events (and
input devices) to the plugin. Below is an example of a MainActivity for a clean Flutter project
that has implemented the required boilerplate code. For many projects it will be possible to simply
duplicate this setup.

```kotlin
package [YOUR_PACKAGE_NAME]

import android.hardware.input.InputManager
import android.os.Handler
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import org.flame_engine.gamepads_android.GamepadsCompatibleActivity

class MainActivity: FlutterActivity(), GamepadsCompatibleActivity {
    var keyListener: ((KeyEvent) -> Boolean)? = null
    var motionListener: ((MotionEvent) -> Boolean)? = null

    override fun dispatchGenericMotionEvent(motionEvent: MotionEvent): Boolean {
        return motionListener?.invoke(motionEvent) ?: false
    }
    
    override fun dispatchKeyEvent(keyEvent: KeyEvent): Boolean {
        if (keyListener?.invoke(keyEvent) == true) {
            return true
        }
        return super.dispatchKeyEvent(keyEvent)
    }

    override fun registerInputDeviceListener(
      listener: InputManager.InputDeviceListener, handler: Handler?) {
        val inputManager = getSystemService(INPUT_SERVICE) as InputManager
        inputManager.registerInputDeviceListener(listener, null)
    }

    override fun registerKeyEventHandler(handler: (KeyEvent) -> Boolean) {
        keyListener = handler
    }

    override fun registerMotionEventHandler(handler: (MotionEvent) -> Boolean) {
        motionListener = handler
    }
}

```


## Support

The simplest way to show us your support is by giving the project a star! :star:

If you want, you can also support us monetarily by donating through OpenCollective:

<a href="https://opencollective.com/blue-fire/donate" target="_blank">
  <img
    src="https://opencollective.com/blue-fire/donate/button@2x.png?color=blue"
    width=200
    alt="Open Collective donate button"
  />
</a>

Through GitHub Sponsors:

<a href="https://github.com/sponsors/bluefireteam" target="_blank">
  <img
    src="https://img.shields.io/badge/Github%20Sponsor-blue?style=for-the-badge&logo=github&logoColor=white"
    width=200
    alt="GitHub Sponsor button"
  />
</a>

Or by becoming a patron on Patreon:

<a href="https://www.patreon.com/bluefireoss" target="_blank">
  <img
   src="https://c5.patreon.com/external/logo/become_a_patron_button.png"
   width=200
   alt="Patreon donate button"
  />
</a>
