# flutter_gamepads

A Flutter plugin to handle gamepad input across multiple platforms.


## Supported interaction

Using just `GamepadControl` out-of-the-box allow users to change focus around your app
similar to using the Tab key, but using the D-pad buttons on their gamepad. Several
'simple' widgets like Buttons, DropdownMenu, Switch etc. just works.

Some more complex interactive widgets like eg. the Slider widget needs some special attention
to support. Another situation is when you have a Scroll view that doesn't receive focus. This
package provides a `GamepadInterceptor` widget that you can use to handle those situations.


### Default bindings

* Activate: A
* Dismiss: B
* Previous focus: D-pad up or D-pad left
* Next focus: D-pad down or D-pad right
* Scroll up: Right stick up
* Scroll down: Right stick down
* Scroll left: Right stick left
* Scroll right: Right stick right


## Usage

### GamepadControl

Wrap your widgets with GamepadControl to allow users to navigate it using their gamepad. It is
recommended to at any given time only have one GamepadControl in your widget tree.

```dart
GamepadControl(
    child: MaterialApp(),
)
```


### GamepadInterceptor

If you want to intercept a Gamepad intent locally next to a Widget you can do so with
`GamepadInterceptor`. Its onBeforeIntent is only called if a descendant widget has focus.

```dart
GamepadInterceptor(
    onBeforeIntent: (intent) {
        if (intent is ScrollIntent) {
            if (intent.direction = AxisDirection.right) {
                setState(() _value = min(100, _value + 10));
            } else if (intent.direction = AxisDirection.left) {
                setState(() _value = max(0, _value - 10));
            }
            // Block actual emit of ScrollIntent
            return false;
        }
        // Allow other intents such as focus change to occur
        return true;
    }
    child: Slider(
        value: _value,
        max: 100,
        // This setState never occur by Gamepad input, but is good to allow keyboard/mouse
        // input as well.
        onChange: (value) => setState(() => _value = value),
    )
)
```

Note that `GamepadInterceptor` must be placed below the `GamepadControl` widget in the
widget tree.


### Changing the Gamepad bindings

You can customize the default gamepad bindings by providing a map between GamepadActivator
and any Intent.

```dart
GamepadControl(
    shortcuts: {
      GamepadActivatorButton.a(): ActivateIntent(),
      GamepadActivatorButton.b(): DismissIntent(),
      // In addition to the .a, .b, .x, .. constructors you can pass in a GamepadButton
      GamepadActivatorButton(GamepadButton.x): DismissIntent(),
      GamepadActivatorButton.bumperLeft(): PreviousFocusIntent(),
      GamepadActivatorButton.bumperRight(): NextFocusIntent(),
      GamepadActivatorAxis.rightStickUp(): ScrollIntent(
        direction: AxisDirection.up,
      ),
      // You can configure an axis with its threshold if you want.
      GamepadActivatorAxis(GamepadAxis.rightStickY, -0.2): ScrollIntent(
        direction: AxisDirection.down,
      ),
    },
    child: child,
)
```


### Temporary disabling Gamepad input

From onBeforeIntent in a GamepadInterceptor or the GamepadControl widget you can return
false to block an intent from being emitted.

On GamepadControl you may also set ignoreEvents = true to an an earlier level temporarily
block all Gamepad input processing. When ignoreEvents is reset to false, all axis input
is reset to default (non-activated) state.
