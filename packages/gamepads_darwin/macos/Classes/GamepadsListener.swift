import Foundation
import GameController

class GamepadsListener {
    var gamepads: [GCExtendedGamepad] = []
    var listener: ((GCExtendedGamepad, GCControllerElement) -> Void)?
    
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
    
    @objc func joystickDidConnect(notification: NSNotification) {
        if let controller = notification.object as? GCController {
            if let gamepad = controller.extendedGamepad {
                gamepads.append(gamepad)
                gamepad.valueChangedHandler = { gamepad, element in
                    if let listener = self.listener {
                        listener(gamepad, element);
                    }
                }
            }
        }
    }
    
    @objc func joystickDidDisconnect(notification: NSNotification) {
        if let controller = notification.object as? GCController {
            gamepads.removeAll(where: { $0 == controller})
        }
    }
}
