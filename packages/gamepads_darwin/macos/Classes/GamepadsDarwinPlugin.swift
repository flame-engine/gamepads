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
        guard let value = getValue(element: element) else {
            return
        }

        let arguments: [String: Any] = [
            "gamepadId": getId(gamepad: gamepad),
            "time": Int(getTimestamp(gamepad: gamepad)),
            "type": element.isAnalog ? "analog" : "button",
            "key": element.sfSymbolsName ?? "Unknown key",
            "value": value,
        ]
        channel.invokeMethod("onGamepadEvent", arguments: arguments)
    }
    
    private func getValue(element: GCControllerElement) -> Float? {
        if let element = element as? GCControllerButtonInput {
            return element.value
        } else if let element = element as? GCControllerAxisInput {
            return element.value
        } else if let element = element as? GCControllerDirectionPad {
            return element.xAxis.value // TODO fix this
        } else {
            return nil
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
