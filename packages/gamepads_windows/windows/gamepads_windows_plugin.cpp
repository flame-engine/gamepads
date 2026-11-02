#include "gamepads_windows_plugin.h"

#include <dbt.h>
#include <hidclass.h>
#include <windows.h>

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <iostream>
#include <memory>
#include <sstream>
#include <utility>

namespace gamepads_windows {
namespace {
constexpr wchar_t kDispatchWindowClass[] = L"gamepads_windows_dispatch";
constexpr UINT kDispatchMessage = WM_APP;
}  // namespace

void GamepadsWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "xyz.luan/gamepads",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<GamepadsWindowsPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

GamepadsWindowsPlugin::GamepadsWindowsPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar(registrar) {
  WNDCLASSW window_class = {};
  window_class.lpfnWndProc = DispatchWindowProc;
  window_class.hInstance = GetModuleHandleW(nullptr);
  window_class.lpszClassName = kDispatchWindowClass;
  RegisterClassW(&window_class);
  dispatch_window_ =
      CreateWindowExW(0, kDispatchWindowClass, L"", 0, 0, 0, 0, 0, HWND_MESSAGE,
                      nullptr, window_class.hInstance, nullptr);
  if (dispatch_window_) {
    SetWindowLongPtrW(dispatch_window_, GWLP_USERDATA,
                      reinterpret_cast<LONG_PTR>(this));
  } else {
    std::cerr << "Failed to create gamepads dispatch window: " << GetLastError()
              << std::endl;
  }
  gamepads.event_emitter = [&](GamepadData* gamepad, const Event& event) {
    this->emit_gamepad_event(gamepad, event);
  };
  gamepads.connection_emitter = [&](const std::string& id,
                                    const std::string& name, bool connected) {
    this->emit_gamepad_connection_event(id, name, connected);
  };
  gamepads.init();
}

GamepadsWindowsPlugin::~GamepadsWindowsPlugin() {
  gamepads.event_emitter.reset();
  gamepads.connection_emitter.reset();
  gamepads.stop();
  HWND window = nullptr;
  {
    std::lock_guard<std::mutex> lock(tasks_mutex_);
    std::swap(window, dispatch_window_);
    tasks_.clear();
  }
  if (window) {
    DestroyWindow(window);
  }
  UnregisterClassW(kDispatchWindowClass, GetModuleHandleW(nullptr));
}

void GamepadsWindowsPlugin::post_to_platform_thread(
    std::function<void()> task) {
  std::lock_guard<std::mutex> lock(tasks_mutex_);
  if (!dispatch_window_)
    return;
  tasks_.push_back(std::move(task));
  if (!posted_)
    posted_ = PostMessageW(dispatch_window_, kDispatchMessage, 0, 0) != 0;
}

void GamepadsWindowsPlugin::drain_tasks() {
  std::vector<std::function<void()>> tasks;
  {
    std::lock_guard<std::mutex> lock(tasks_mutex_);
    tasks.swap(tasks_);
    posted_ = false;
  }
  for (auto& task : tasks)
    task();
}

LRESULT CALLBACK GamepadsWindowsPlugin::DispatchWindowProc(HWND hwnd,
                                                           UINT message,
                                                           WPARAM wparam,
                                                           LPARAM lparam) {
  if (message == kDispatchMessage) {
    auto plugin = reinterpret_cast<GamepadsWindowsPlugin*>(
        GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (plugin)
      plugin->drain_tasks();
    return 0;
  }
  return DefWindowProcW(hwnd, message, wparam, lparam);
}

void GamepadsWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = method_call.method_name();
  if (method == "rumble" || method == "hasRumble" || method == "stopRumble") {
    if (!rumble_)
      rumble_ = std::make_unique<GamepadRumble>();
    const auto* args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!args) {
      result->Success(flutter::EncodableValue(false));
      return;
    }
    const auto idIt = args->find(flutter::EncodableValue("gamepadId"));
    if (idIt == args->end() ||
        !std::holds_alternative<std::string>(idIt->second)) {
      result->Success(flutter::EncodableValue(false));
      return;
    }
    const auto& id = std::get<std::string>(idIt->second);
    bool accepted = false;
    if (method == "hasRumble")
      accepted = rumble_->Has(id);
    else if (method == "stopRumble")
      accepted = rumble_->Set(id, 0, 0, 0);
    else {
      const auto low = args->find(flutter::EncodableValue("lowFrequency"));
      const auto high = args->find(flutter::EncodableValue("highFrequency"));
      const auto duration =
          args->find(flutter::EncodableValue("durationMillis"));
      if (low != args->end() && high != args->end() &&
          duration != args->end() &&
          std::holds_alternative<double>(low->second) &&
          std::holds_alternative<double>(high->second) &&
          std::holds_alternative<int32_t>(duration->second)) {
        accepted = rumble_->Set(id, std::get<double>(low->second),
                                std::get<double>(high->second),
                                std::get<int32_t>(duration->second));
      }
    }
    result->Success(flutter::EncodableValue(accepted));
    return;
  }
  if (method_call.method_name().compare("listGamepads") == 0) {
    flutter::EncodableList list;
    for (auto gamepad : gamepads.get_gamepads()) {
      flutter::EncodableMap map;
      map[flutter::EncodableValue("id")] = flutter::EncodableValue(gamepad->id);
      map[flutter::EncodableValue("name")] =
          flutter::EncodableValue(gamepad->name);
      map[flutter::EncodableValue("vendorId")] =
          flutter::EncodableValue(gamepad->vendor_id);
      map[flutter::EncodableValue("productId")] =
          flutter::EncodableValue(gamepad->product_id);
      list.push_back(flutter::EncodableValue(map));
    }
    result->Success(flutter::EncodableValue(list));
  } else {
    result->NotImplemented();
  }
}

void GamepadsWindowsPlugin::emit_gamepad_event(GamepadData* gamepad,
                                               const Event& event) {
  auto _channel = this->channel.get();
  if (_channel) {
    flutter::EncodableMap map;
    map[flutter::EncodableValue("gamepadId")] =
        flutter::EncodableValue(gamepad->id);
    map[flutter::EncodableValue("time")] = flutter::EncodableValue(event.time);
    map[flutter::EncodableValue("type")] = flutter::EncodableValue(event.type);
    map[flutter::EncodableValue("key")] = flutter::EncodableValue(event.key);
    map[flutter::EncodableValue("value")] =
        flutter::EncodableValue(event.value);
    map[flutter::EncodableValue("vendorId")] =
        flutter::EncodableValue(gamepad->vendor_id);
    map[flutter::EncodableValue("productId")] =
        flutter::EncodableValue(gamepad->product_id);
    // Built here (`gamepad` may be freed once its thread exits), sent from
    // the platform thread.
    post_to_platform_thread([map = std::move(map)]() {
      if (auto c = channel.get()) {
        c->InvokeMethod("onGamepadEvent",
                        std::make_unique<flutter::EncodableValue>(map));
      }
    });
  }
}

void GamepadsWindowsPlugin::emit_gamepad_connection_event(
    const std::string& id,
    const std::string& name,
    bool connected) {
  auto _channel = this->channel.get();
  if (_channel) {
    flutter::EncodableMap map;
    map[flutter::EncodableValue("gamepadId")] = flutter::EncodableValue(id);
    map[flutter::EncodableValue("name")] = flutter::EncodableValue(name);
    map[flutter::EncodableValue("type")] =
        flutter::EncodableValue(connected ? "connected" : "disconnected");
    post_to_platform_thread([map = std::move(map)]() {
      if (auto c = channel.get()) {
        c->InvokeMethod("onGamepadConnectionEvent",
                        std::make_unique<flutter::EncodableValue>(map));
      }
    });
  }
}
}  // namespace gamepads_windows
