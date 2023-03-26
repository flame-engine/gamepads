import Cocoa
import GameController
import FlutterMacOS

public class GamepadsDarwinPlugin: NSObject, FlutterPlugin {
    var gamepads = GamepadsListener(listener: onGamepadEvent)
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "xyz.luan/gamepads", binaryMessenger: registrar.messenger)
        let instance = GamepadsDarwinPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "listGamepads":
            result(listGamepads())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private static func onGamepadEvent(gamepad: GCMicroGamepad, element: GCControllerElement) {
        print("Joystick input: \(gamepad.dpad.xAxis.value), \(gamepad.dpad.yAxis.value)")
    }
    
    private func listGamepads() -> [String] {
        return gamepads.gamepads.map { $0.description }
    }
}
