import Cocoa
import GameController
import FlutterMacOS

public class GamepadsDarwinPlugin: NSObject, FlutterPlugin {
    let channel: FlutterMethodChannel
    let gamepads = GamepadsListener()
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        
        self.gamepads.listener = onGamepadEvent
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "xyz.luan/gamepads", binaryMessenger: registrar.messenger)
        let instance = GamepadsDarwinPlugin(channel: channel)
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
    
    private func onGamepadEvent(gamepad: GCExtendedGamepad, element: GCControllerElement) {
        for (key, value) in getValues(element: element) {
            let arguments: [String: Any] = [
                "gamepadId": getId(gamepad: gamepad),
                "time": Int(getTimestamp(gamepad: gamepad)),
                "type": element.isAnalog ? "analog" : "button",
                "key": key,
                "value": value,
            ]
            channel.invokeMethod("onGamepadEvent", arguments: arguments)
        }
    }
    
    private func getValues(element: GCControllerElement) -> [(String, Float)] {
        if let element = element as? GCControllerButtonInput {
            return [(element.sfSymbolsName ?? "Unknown button", element.value)]
        } else if let element = element as? GCControllerAxisInput {
            return [(element.sfSymbolsName ?? "Unknown axis", element.value)]
        } else if let element = element as? GCControllerDirectionPad {
            return [
                ("\(element.sfSymbolsName ?? "") xAxis", element.xAxis.value),
                ("\(element.sfSymbolsName ?? "") yAxis", element.yAxis.value)
            ]
        } else {
            return []
        }
    }
    
    private func getTimestamp(gamepad: GCExtendedGamepad) -> TimeInterval {
        if #available(macOS 11.0, *) {
            return gamepad.lastEventTimestamp
        } else {
            return Date().timeIntervalSince1970
        }
    }
    
    private func getId(gamepad: GCExtendedGamepad) -> String {
        if #available(macOS 11.0, *) {
            return gamepad.device?.productCategory ?? "Unknown device"
        } else {
            return "Unknown device"
        }
    }
    
    private func listGamepads() -> [[String: Any?]] {
        return gamepads.gamepads.map { [ "id": getId(gamepad: $0) ] }
    }
}
