#ifndef FLUTTER_PLUGIN_GAMEPADS_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_GAMEPADS_WINDOWS_PLUGIN_H_

#include "rumble.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <functional>
#include <memory>
#include <mutex>
#include <vector>

#include "gamepad.h"

namespace gamepads_windows {

class GamepadsWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  GamepadsWindowsPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~GamepadsWindowsPlugin();

  // Disallow copy and assign.
  GamepadsWindowsPlugin(const GamepadsWindowsPlugin&) = delete;
  GamepadsWindowsPlugin& operator=(const GamepadsWindowsPlugin&) = delete;

 private:
  std::unique_ptr<GamepadRumble> rumble_;
  flutter::PluginRegistrarWindows* registrar;
  static inline std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      channel{};

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void emit_gamepad_event(GamepadData* gamepad, const Event& event);

  void emit_gamepad_connection_event(const std::string& id,
                                     const std::string& name,
                                     bool connected);

  // GameInput callbacks and read threads are not the platform thread.
  // Channel messages are queued and sent from a message-only window owned by
  // the plugin, which works whether or not the host forwards window messages.
  void post_to_platform_thread(std::function<void()> task);
  void drain_tasks();
  static LRESULT CALLBACK DispatchWindowProc(HWND hwnd,
                                             UINT message,
                                             WPARAM wparam,
                                             LPARAM lparam);

  HWND dispatch_window_ = nullptr;
  bool posted_ = false;  // a dispatch message is pending (tasks_mutex_)
  std::mutex tasks_mutex_;
  std::vector<std::function<void()>> tasks_;
};

}  // namespace gamepads_windows

#endif  // FLUTTER_PLUGIN_GAMEPADS_WINDOWS_PLUGIN_H_
