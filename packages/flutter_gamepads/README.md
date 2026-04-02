# flutter_gamepads

A Flutter package that maps gamepad input to UI interaction. It is based on the same
Flutter focus and intent systems that keyboard navigation in Flutter at its core is based on.

This means that for a large part, the same effort you spend on supporting keyboard and
screen reader users also benefit gamepad users and vice versa.

The philosophy is that you just add Gamepad support to your app to extend its multi-modality
of user input.


## Supported interaction

Using just `GamepadControl` users of your app can move focus around your app similar to using
the Tab key, but using the D-pad buttons on their gamepad. Several 'simple' widgets like
buttons, DropdownMenu, Switch etc. just works.

Some more complex interactive widgets like eg. the Slider widget needs some special attention
to support. This package provides a `GamepadInterceptor` widget that you can use to handle
those situations.


## Usage


### GamepadControl

Wrap your widgets with `GamepadControl` to allow users to navigate it using their gamepad. It is
recommended to at any given time only have one `GamepadControl` in your widget tree.

```dart
GamepadControl(
    child: MaterialApp(),
)
```

That will give you these default input bindings:

* Activate: A
* Dismiss: B
* Previous focus: D-pad up or D-pad left
* Next focus: D-pad down or D-pad right
* Scroll up: Right stick up
* Scroll down: Right stick down
* Scroll left: Right stick left
* Scroll right: Right stick right


### GamepadInterceptor

If you want to intercept a Gamepad intent locally next to a Widget you can do so with
`GamepadInterceptor`. Its `onBeforeIntent` is only called if a descendant widget has focus.

```dart
GamepadInterceptor(
    onBeforeIntent: (activator, intent) {
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

An example of how to package an Gamepad-extended widget can be found in
[SliderWithGamepadExport](https://github.com/flame-engine/gamepads/tree/main/packages/flutter_example/example/lib/flutter_example/pages/slider_with_gamepad_support.dart).


### Changing the Gamepad bindings

You can customize the default gamepad bindings by providing a map between `GamepadActivator`
and any `Intent`. Flutter comes with a set of generally supported intents, but you can also
pass in your custom Intents as long as you provide Actions for them.

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

From `onBeforeIntent` in a `GamepadInterceptor` or the `GamepadControl` widget you can return
false to block an intent from being emitted.

On `GamepadControl` you may also set `ignoreEvents = true` to an an earlier level temporarily
block all Gamepad input processing. Setting `ignoreEvents` to true does clear currently activated
axes and resets repeats, while `onBeforeIntent` just block each intent from being emitted.


## Implementation strategy recommendation


### Step 1 - Clear focus indicators

Use the TAB key on your keyboard and step through your app and verify that your widgets
clearly show if they are focused or not.

You may have to update your Theme and add an expressive border of the focused buttons for
example.

If you notice that some widgets never receives focus you have to resolve this, by making
them focusable and verify with the TAB key this works.


### Step 2 - Add default GamepadControl

Start with wrapping your MaterialApp or similar with the `GamepadControl` and then
try out your app with a gamepad. Take notice of which widgets in your app that doesn't
work out-of-the box.

```dart
GamepadControl(
    child: MaterialApp(),
)
```


### Step 3 - Add interceptors where needed

Then, wrap those problematic widgets with `GamepadInterceptor` and ensure that the widget
itself can receive focus.

Use `onBeforeIntent` to catch eg. the `ScrollIntent` and use that to implement interaction
with your widget.

Then test and repeat.


### Flame specific guidance

`flutter_gamepad` can be helpful in scenarios when you have overlays in your
Flame game that you want users to be able to navigate with their gamepad.

1. Wrap your `GameWidget` with a `GamepadControl` widget
2. For overlays that represent a modal dialog, you will need to trap the focus
   in the dialog. See
   [OverlayDialogBackdrop](https://github.com/flame-engine/gamepads/tree/main/packages/flutter_example/example/lib/flame_example/overlays/overlay_dialog_backdrop.dart)
   in Flame example app for how you can do that. In that example the dialog itself
   will receive the focus so that when a mouse user opens the dialog, it won't show
   a focus indicator on a button in the dialog.
3. To close overlay dialogs on DismissIntent, you will need to catch it with
   `onBeforeIntent` and close the overlay. In
   [Flame Example](https://github.com/flame-engine/gamepads/tree/main/packages/flutter_example/example/lib/flame_example/main.dart)
   this is done generically at the root, but could instead wrap each dialog in a
   `GamepadInterceptor` to do it locally if you need to guard closing the dialog
   by some condition.
4. If you need to disable `GamepadControl` while in-game you can do so by setting
   `ignoreEvents = true` on it.
