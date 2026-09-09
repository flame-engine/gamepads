# gamepads_test

A utility package for [*gamepads*](https://pub.dev/packages/gamepads) to help writing tests.

Provides `GamepadsTester` which you can use to emit raw (non-normalized) events into the gamepads
event stream.

Given that the emitted events matches the raw one of the normalizer platform, gamepads will emit
also normalized events for your tested app code.

## Usage

Add this package to your dev dependencies, as you typically only will use this package
in your tests.

Start by setting a normalizer if the code that you will test has event listeners on
`Gamepads.normalizedEvents` or your app uses a package such as `flame_gamepads` or
`flutter_gamepads` that depends on normalized events.

```dart
WidgetsFlutterBinding.ensureInitialized();
GamepadsTester.setNormalizer(GamepadPlatform.windows);
```

Then use these methods to emit events:

* `GampadsTester.emitRawButton(String rawButton, double value)` - emit a button event
* `GampadsTester.emitRawAnalog(String rawAnalog, double value)` - emit an analog/axis event
* `GampadsTester.emitRawButtonPress(String rawButton)` - emit two button events for button down,
  button up


## Raw button/analog names

Since emitted events are non-normalized Gamepads events, you will have to lookup the
raw, non-normalized name for the platform of the selected normalizer platform.

A source of this information is the mapping files which you
find in
[`lib/src/mappings`](https://github.com/flame-engine/gamepads/tree/main/packages/gamepads/lib/src/mappings)
of the *gamepads* package.

Just make sure to read the mapping file that corresponds to the GamepadPlatform you set
explicitly via `GamepadsTester.setNormalizer()` to ensure your tests pass regardless of
actual platform they run on.
