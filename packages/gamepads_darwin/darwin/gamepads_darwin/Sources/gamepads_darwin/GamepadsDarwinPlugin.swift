import Foundation
import GameController

#if os(macOS)
import FlutterMacOS
#else
import Flutter
#endif

enum FixedKey: String {
    case buttonMenu
    case buttonOptions
    case buttonHome
    case touchpadButton
}

public class GamepadsDarwinPlugin: NSObject, FlutterPlugin {
    let channel: FlutterMethodChannel
    let gamepads = GamepadsListener()
    private var rumbleBackend: Any?
    @available(macOS 11.0, iOS 14.0, *)
    private var rumble: GamepadRumble {
        if let value = rumbleBackend as? GamepadRumble { return value }
        let value = GamepadRumble()
        rumbleBackend = value
        return value
    }

    /// The name each gamepad had when it connected. By the time it
    /// disconnects its `GCDevice` is usually already gone, and `getName`
    /// would fall back to "Unknown device".
    private var gamepadNames = [Int: String]()

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()

        self.gamepads.listener = onGamepadEvent
        self.gamepads.discoverConnectedControllers()
        self.gamepads.connectionListener = onGamepadConnectionEvent
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(macOS)
        let messenger = registrar.messenger
        #else
        let messenger = registrar.messenger()
        #endif
        let channel = FlutterMethodChannel(name: "xyz.luan/gamepads", binaryMessenger: messenger)
        let instance = GamepadsDarwinPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "hasRumble", "rumble", "stopRumble":
            guard #available(macOS 11.0, iOS 14.0, *),
                  let args = call.arguments as? [String: Any],
                  let id = args["gamepadId"] as? String,
                  let index = Int(id),
                  let gamepad = gamepads.gamepad(for: index),
                  let controller = gamepad.controller else { result(false); return }
            if call.method == "hasRumble" { result(rumble.has(controller)); return }
            if call.method == "stopRumble" { rumble.stop(controller); result(true); return }
            guard let low = args["lowFrequency"] as? Double,
                  let high = args["highFrequency"] as? Double,
                  let duration = args["durationMillis"] as? Int else { result(false); return }
            result(rumble.set(controller, low: low, high: high, duration: duration))
        case "listGamepads":
            result(listGamepads())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func onGamepadEvent(gamepadId: Int, gamepad: GCExtendedGamepad, element: GCControllerElement) {
        let fixedKey = getFixedKey(gamepad: gamepad, element: element)
        for (key, value) in getValues(element: element, fixedKey: fixedKey) {
            let arguments: [String: Any] = [
                "gamepadId": String(gamepadId),
                "time": Int(getTimestamp(gamepad: gamepad)),
                "type": element.isAnalog ? "analog" : "button",
                "key": key,
                "value": value,
            ]
            channel.invokeMethod("onGamepadEvent", arguments: arguments)
        }
    }

    private func onGamepadConnectionEvent(gamepadId: Int, gamepad: GCExtendedGamepad, connected: Bool) {
        let name: String
        if connected {
            name = getName(gamepad: gamepad)
            gamepadNames[gamepadId] = name
        } else {
            name = gamepadNames.removeValue(forKey: gamepadId) ?? getName(gamepad: gamepad)
        }
        let arguments: [String: Any] = [
            "gamepadId": String(gamepadId),
            "name": name,
            "type": connected ? "connected" : "disconnected",
        ]
        channel.invokeMethod("onGamepadConnectionEvent", arguments: arguments)
    }

    /// Returns a fixed key name for elements whose SF Symbol names are
    /// ambiguous across controller types (e.g. both DualSense system
    /// buttons report "capsule.portrait"). For other elements, returns
    /// nil so the caller falls back to SF Symbol names.
    private func getFixedKey(gamepad: GCExtendedGamepad, element: GCControllerElement) -> FixedKey? {
        if element === gamepad.buttonMenu {
            return .buttonMenu
        }
        if let opt = gamepad.buttonOptions, element === opt {
            return .buttonOptions
        }
        if #available(iOS 14.0, macOS 11.0, *) {
            if let home = gamepad.buttonHome, element === home {
                return .buttonHome
            }
        }
        if #available(iOS 14.5, macOS 11.3, *) {
            if let ds = gamepad as? GCDualSenseGamepad,
               element === ds.touchpadButton {
                return .touchpadButton
            }
        }
        if #available(iOS 14.0, macOS 11.0, *) {
            if let ds = gamepad as? GCDualShockGamepad,
               element === ds.touchpadButton {
                return .touchpadButton
            }
        }
        return nil
    }

    private func getValues(element: GCControllerElement, fixedKey: FixedKey? = nil) -> [(String, Float)] {
        if let element = element as? GCControllerButtonInput {
            var button: String = fixedKey?.rawValue ?? "Unknown button"
            if fixedKey == nil {
                if #available(iOS 14.0, macOS 11.0, *) {
                    if let name = element.sfSymbolsName {
                        button = name
                    }
                }
            }
            return [(button, element.value)]
        } else if let element = element as? GCControllerAxisInput {
            var axis: String = fixedKey?.rawValue ?? "Unknown axis"
            if fixedKey == nil {
                if #available(iOS 14.0, macOS 11.0, *) {
                    if let name = element.sfSymbolsName {
                        axis = name
                    }
                }
            }
            return [(axis, element.value)]
        } else if let element = element as? GCControllerDirectionPad {
            var directionPad: String = fixedKey?.rawValue ?? "Unknown direction pad"
            if fixedKey == nil {
                if #available(iOS 14.0, macOS 11.0, *) {
                    if let name = element.sfSymbolsName {
                        directionPad = name
                    }
                }
            }
            return [
                (maybeConcat(directionPad, "xAxis"), element.xAxis.value),
                (maybeConcat(directionPad, "yAxis"), element.yAxis.value)
            ]
        } else {
            return []
        }
    }

    private func getNameForElement(element: GCControllerElement) -> String? {
        if #available(iOS 14.0, macOS 11.0, *) {
            return element.sfSymbolsName
        } else {
            return nil
        }
    }

    private func getTimestamp(gamepad: GCExtendedGamepad) -> TimeInterval {
        if #available(iOS 14.0, macOS 11.0, *) {
            return gamepad.lastEventTimestamp
        } else {
            return Date().timeIntervalSince1970
        }
    }

    private func getName(gamepad: GCExtendedGamepad) -> String {
        if #available(iOS 14.0, macOS 11.0, *) {
            let device = gamepad.device
            return maybeConcat(device?.vendorName, device?.productCategory) ?? "Unknown device"
        } else {
            return "Unknown device"
        }
    }

    private func listGamepads() -> [[String: Any?]] {
        return gamepads.gamepads.enumerated().map { (index, gamepad) in
            [ "id": String(gamepads.id(for: gamepad)), "name": getName(gamepad: gamepad) ]
        }
    }

    private func maybeConcat(_ string1: String?, _ string2: String) -> String {
        return maybeConcat(string1, string2)!
    }

    private func maybeConcat(_ strings: String?...) -> String? {
        let nonNull = strings.compactMap { $0 }
        if (nonNull.isEmpty) {
            return nil
        }
        return nonNull.joined(separator: " - ")
    }
}

extension Optional {
    func map<T>(_ closure: (Wrapped) -> T) -> T? {
        if let value = self {
            return closure(value)
        } else {
            return nil
        }
    }
}
