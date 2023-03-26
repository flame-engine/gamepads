import Foundation
import GameController

class GamepadsListener {
    var gamepads: [GCController] = []
    let listener: (GCMicroGamepad, GCControllerElement) -> Void
    
    init(listener: @escaping (GCMicroGamepad, GCControllerElement) -> Void) {
        self.listener = listener
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
            gamepads.append(controller)
            controller.microGamepad?.valueChangedHandler = listener
        }
    }
    
    @objc func joystickDidDisconnect(notification: NSNotification) {
        if let controller = notification.object as? GCController {
            gamepads.removeAll(where: { $0 == controller})
        }
    }
}
