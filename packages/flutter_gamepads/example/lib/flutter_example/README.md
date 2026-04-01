# flutter_gamepads example

A simple example project showcasing the flutter_gamepads plugin.

All gamepad input in this app is provided via `flutter_gamepads` package. It uses `GamepadInterceptor`
in some places to to provide gamepad support for certain widgets or scenarios that does not
work out of the box with just wrapping the app with `GamepadControl`.
