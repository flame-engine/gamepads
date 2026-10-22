#include "rumble.h"

#include "include/gamepads_linux/gamepads_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>

#include <atomic>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <sstream>
#include <thread>

#include "connection_listener.h"
#include "gamepad.h"

#define GAMEPADS_LINUX_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), gamepads_linux_plugin_get_type(), \
                              GamepadsLinuxPlugin))

struct _GamepadsLinuxPlugin {
  GObject parent_instance;
  GamepadRumble* rumble;
};

G_DEFINE_TYPE(GamepadsLinuxPlugin, gamepads_linux_plugin, g_object_get_type())

static FlMethodChannel* channel;

std::atomic<bool> keep_reading_events = false;
std::map<std::string, std::shared_ptr<gamepad::GamepadInfo>> gamepads = {};
std::mutex gamepads_mutex;

struct PendingMessage {
  const char* method;
  FlValue* args;
};

static gboolean send_pending_message(gpointer data) {
  auto* message = static_cast<PendingMessage*>(data);
  if (channel) {
    fl_method_channel_invoke_method(channel, message->method, message->args,
                                    nullptr, nullptr, nullptr);
  }
  return G_SOURCE_REMOVE;
}

static void free_pending_message(gpointer data) {
  auto* message = static_cast<PendingMessage*>(data);
  fl_value_unref(message->args);
  delete message;
}

static void invoke_on_platform_thread(const char* method, FlValue* args) {
  g_idle_add_full(G_PRIORITY_DEFAULT, send_pending_message,
                  new PendingMessage{method, args}, free_pending_message);
}

static std::optional<std::string> parse_event_type(js_event event) {
  switch (event.type & ~JS_EVENT_INIT) {
    case JS_EVENT_BUTTON: {
      return "button";
    }
    case JS_EVENT_AXIS: {
      return "analog";
    }
    default: {
      std::cerr << "Unknown event type " << +event.type << std::endl;
      return std::nullopt;
    }
  }
}

static void emit_gamepad_event(const gamepad::GamepadInfo& gamepad,
                               const js_event& event) {
  std::optional<std::string> type = parse_event_type(event);
  if (!type) {
    return;
  }
  std::lock_guard<std::mutex> lock(gamepads_mutex);
  if (!gamepad.alive) {
    return;
  }
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "gamepadId",
                           fl_value_new_string(gamepad.device_id.c_str()));
  fl_value_set_string_take(map, "time", fl_value_new_int(event.time));
  fl_value_set_string_take(map, "type", fl_value_new_string(type->c_str()));
  fl_value_set_string_take(
      map, "key", fl_value_new_string(std::to_string(event.number).c_str()));
  fl_value_set_string_take(map, "value", fl_value_new_float(event.value));
  fl_value_set_string_take(map, "vendorId",
                           fl_value_new_int(gamepad.vendor_id));
  fl_value_set_string_take(map, "productId",
                           fl_value_new_int(gamepad.product_id));
  invoke_on_platform_thread("onGamepadEvent", map);
}

static void emit_gamepad_connection_event(const std::string& device_id,
                                          const std::string& name,
                                          bool connected) {
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "gamepadId",
                           fl_value_new_string(device_id.c_str()));
  fl_value_set_string_take(map, "name", fl_value_new_string(name.c_str()));
  fl_value_set_string_take(
      map, "type",
      fl_value_new_string(connected ? "connected" : "disconnected"));
  invoke_on_platform_thread("onGamepadConnectionEvent", map);
}

static void respond_not_found(FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  fl_method_call_respond(method_call, response, nullptr);
}

static void respond(FlMethodCall* method_call, FlValue* value) {
  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  fl_method_call_respond(method_call, response, nullptr);
}

static void gamepads_linux_plugin_handle_method_call(
    GamepadsLinuxPlugin* self,
    FlMethodCall* method_call) {
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "rumble") == 0 || strcmp(method, "hasRumble") == 0 ||
      strcmp(method, "stopRumble") == 0) {
    auto* args = fl_method_call_get_args(method_call);
    bool accepted = false;
    if (args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      auto* id = fl_value_lookup_string(args, "gamepadId");
      if (id && fl_value_get_type(id) == FL_VALUE_TYPE_STRING) {
        const std::string key = fl_value_get_string(id);
        if (strcmp(method, "hasRumble") == 0)
          accepted = self->rumble->Has(key);
        else if (strcmp(method, "stopRumble") == 0)
          accepted = self->rumble->Stop(key);
        else {
          auto* low = fl_value_lookup_string(args, "lowFrequency");
          auto* high = fl_value_lookup_string(args, "highFrequency");
          auto* duration = fl_value_lookup_string(args, "durationMillis");
          if (low && high && duration &&
              fl_value_get_type(low) == FL_VALUE_TYPE_FLOAT &&
              fl_value_get_type(high) == FL_VALUE_TYPE_FLOAT &&
              fl_value_get_type(duration) == FL_VALUE_TYPE_INT &&
              fl_value_get_int(duration) >= 0 &&
              fl_value_get_int(duration) <= 30000) {
            accepted = self->rumble->Set(
                key, fl_value_get_float(low), fl_value_get_float(high),
                static_cast<int>(fl_value_get_int(duration)));
          }
        }
      }
    }
    g_autoptr(FlValue) value = fl_value_new_bool(accepted);
    respond(method_call, value);
    return;
  }
  if (strcmp(method, "listGamepads") == 0) {
    g_autoptr(FlValue) list = fl_value_new_list();
    std::lock_guard<std::mutex> lock(gamepads_mutex);
    for (const auto& [device_id, gamepad] : gamepads) {
      g_autoptr(FlValue) map = fl_value_new_map();
      fl_value_set_string_take(map, "id",
                               fl_value_new_string(device_id.c_str()));
      fl_value_set_string_take(map, "name",
                               fl_value_new_string(gamepad->name.c_str()));
      fl_value_set_string_take(map, "vendorId",
                               fl_value_new_int(gamepad->vendor_id));
      fl_value_set_string_take(map, "productId",
                               fl_value_new_int(gamepad->product_id));
      fl_value_append(list, map);
    }
    respond(method_call, list);
  } else {
    respond_not_found(method_call);
  }
}

static void method_call_cb([[maybe_unused]] FlMethodChannel* flutter_channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  GamepadsLinuxPlugin* plugin = GAMEPADS_LINUX_PLUGIN(user_data);
  gamepads_linux_plugin_handle_method_call(plugin, method_call);
}

void gamepads_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  GamepadsLinuxPlugin* plugin = GAMEPADS_LINUX_PLUGIN(
      g_object_new(gamepads_linux_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  channel = fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                                  "xyz.luan/gamepads", FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}

static void remove_gamepad(
    const std::string& device_id,
    const std::shared_ptr<gamepad::GamepadInfo>& expected) {
  std::lock_guard<std::mutex> lock(gamepads_mutex);
  auto existing = gamepads.find(device_id);
  if (existing == gamepads.end() ||
      (expected && existing->second != expected)) {
    return;
  }
  std::cout << "Gamepad disconnected " << device_id << std::endl;
  existing->second->alive = false;
  const std::string name = existing->second->name;
  gamepads.erase(existing);
  emit_gamepad_connection_event(device_id, name, false);
}

void process_connection_event(std::shared_ptr<gamepad::GamepadInfo> gamepad) {
  gamepad::listen(gamepad, [gamepad](const js_event& value) {
    emit_gamepad_event(*gamepad, value);
  });
  remove_gamepad(gamepad->device_id, gamepad);
}

void event_loop_start() {
  connection_listener::listen(
      &keep_reading_events,
      [](const connection_listener::ConnectionEvent& event) {
        std::string key = event.device_id;
        if (event.type ==
            connection_listener::ConnectionEventType::DISCONNECTED) {
          remove_gamepad(key, nullptr);
          return;
        }

        {
          std::lock_guard<std::mutex> lock(gamepads_mutex);
          if (gamepads.count(key) > 0) {
            std::cout << "Existing gamepad found; skipping" << std::endl;
            return;
          }
        }

        std::shared_ptr<gamepad::GamepadInfo> info =
            gamepad::get_gamepad_info(key);
        if (!info) {
          std::cerr << "Unable to open joystick for reading " << key
                    << std::endl;
          return;
        }

        std::cout << "Gamepad connected " << key << " - " << info->name
                  << std::endl;
        {
          std::lock_guard<std::mutex> lock(gamepads_mutex);
          gamepads[key] = info;
          emit_gamepad_connection_event(key, info->name, true);
        }

        std::thread input_thread(process_connection_event, info);
        input_thread.detach();
      });
}

static void gamepads_linux_plugin_dispose(GObject* object) {
  auto* self = GAMEPADS_LINUX_PLUGIN(object);
  delete self->rumble;
  self->rumble = nullptr;
  keep_reading_events = false;
  {
    std::lock_guard<std::mutex> lock(gamepads_mutex);
    for (const auto& [device_id, gamepad] : gamepads) {
      gamepad->alive = false;
    }
    gamepads.clear();
  }
  G_OBJECT_CLASS(gamepads_linux_plugin_parent_class)->dispose(object);
}

static void gamepads_linux_plugin_class_init(GamepadsLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = gamepads_linux_plugin_dispose;
}

static void gamepads_linux_plugin_init(GamepadsLinuxPlugin* self) {
  self->rumble = new GamepadRumble();
  keep_reading_events = true;

  std::thread event_loop_thread(event_loop_start);
  event_loop_thread.detach();
}
