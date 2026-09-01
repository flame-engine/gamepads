import Foundation
import GameController

class GamepadsListener {
    var gamepads: [GCExtendedGamepad] = []
    var listener: ((Int, GCExtendedGamepad, GCControllerElement) -> Void)?
    var connectionListener: ((Int, GCExtendedGamepad, Bool) -> Void)?

    /// The id each gamepad was given when it connected. Looking the id up
    /// again on disconnect would return a different one, since removing a
    /// gamepad shifts the indices of the ones after it.
    private var gamepadIds: [ObjectIdentifier: Int] = [:]

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(joystickDidConnect),
            name: .GCControllerDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(joystickDidDisconnect),
            name: .GCControllerDidDisconnect,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
 
    @objc private func joystickDidConnect(notification: NSNotification) {
        if let controller = notification.object as? GCController {
            if let gamepad = controller.extendedGamepad {
                gamepads.append(gamepad)
                let gamepadId = getAndSetPlayerId(of: gamepad)
                gamepadIds[ObjectIdentifier(gamepad)] = gamepadId

                gamepad.valueChangedHandler = { gamepad, element in
                    if let listener = self.listener {
                        listener(gamepadId, gamepad, element);
                    }
                }

                connectionListener?(gamepadId, gamepad, true)
            }
        }
    }

    @objc private func joystickDidDisconnect(notification: NSNotification) {
        if let controller = notification.object as? GCController {
            if let gamepad = controller.extendedGamepad {
                gamepads.removeAll(where: { $0 == gamepad })
                if let gamepadId = gamepadIds.removeValue(forKey: ObjectIdentifier(gamepad)) {
                    connectionListener?(gamepadId, gamepad, false)
                }
            }
        }
    }

    private func getAndSetPlayerId(of gamepad: GCExtendedGamepad) -> Int {
        let gamepadId = gamepads.firstIndex(of: gamepad) ?? -1
        gamepad.controller?.playerIndex = toPlayerIndex(index: gamepadId)
        return gamepadId
    }

    private func toPlayerIndex(index: Int) -> GCControllerPlayerIndex {
        switch index {
        case 0:
            return GCControllerPlayerIndex.index1
        case 1:
            return GCControllerPlayerIndex.index2
        case 2:
            return GCControllerPlayerIndex.index3
        case 3:
            return GCControllerPlayerIndex.index4
        default:
            return GCControllerPlayerIndex.indexUnset
        }
    }
}
