#include "rumble.h"

#include "include/gamepads_linux/gamepads_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>

#include <iostream>
#include <map>
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

bool keep_reading_events = false;
std::map<std::string, gamepad::GamepadInfo> gamepads = {};

static std::string parse_event_type(js_event event) {
  switch (event.type & ~JS_EVENT_INIT) {
    case JS_EVENT_BUTTON: {
      return "button";
    }
    case JS_EVENT_AXIS: {
      return "analog";
    }
    default: {
      std::cerr << "Unknown event type " << event.type << std::endl;
      throw std::invalid_argument("Unknown event type");
    }
  }
}

static void emit_gamepad_event(gamepad::GamepadInfo* gamepad,
                               const js_event& event) {
  if (channel) {
    g_autoptr(FlValue) map = fl_value_new_map();
    fl_value_set_string(map, "gamepadId",
                        fl_value_new_string(gamepad->device_id.c_str()));
    fl_value_set_string(map, "time", fl_value_new_int(event.time));
    fl_value_set_string(map, "type",
                        fl_value_new_string(parse_event_type(event).c_str()));
    fl_value_set_string(
        map, "key", fl_value_new_string(std::to_string(event.number).c_str()));
    fl_value_set_string(map, "value", fl_value_new_float(event.value));
    fl_value_set_string(map, "vendorId", fl_value_new_int(gamepad->vendor_id));
    fl_value_set_string(map, "productId",
                        fl_value_new_int(gamepad->product_id));
    fl_method_channel_invoke_method(channel, "onGamepadEvent", map, nullptr,
                                    nullptr, nullptr);
  }
}

static void emit_gamepad_connection_event(const std::string& device_id,
                                          const std::string& name,
                                          bool connected) {
  if (channel) {
    g_autoptr(FlValue) map = fl_value_new_map();
    fl_value_set_string(map, "gamepadId",
                        fl_value_new_string(device_id.c_str()));
    fl_value_set_string(map, "name", fl_value_new_string(name.c_str()));
    fl_value_set_string(
        map, "type",
        fl_value_new_string(connected ? "connected" : "disconnected"));
    fl_method_channel_invoke_method(channel, "onGamepadConnectionEvent", map,
                                    nullptr, nullptr, nullptr);
  }
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
    for (auto [device_id, gamepad] : gamepads) {
      g_autoptr(FlValue) map = fl_value_new_map();
      fl_value_set(map, fl_value_new_string("id"),
                   fl_value_new_string(device_id.c_str()));
      fl_value_set(map, fl_value_new_string("name"),
                   fl_value_new_string(gamepad.name.c_str()));
      fl_value_set(map, fl_value_new_string("vendorId"),
                   fl_value_new_int(gamepad.vendor_id));
      fl_value_set(map, fl_value_new_string("productId"),
                   fl_value_new_int(gamepad.product_id));
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

void process_connection_event(gamepad::GamepadInfo* gamepad) {
  gamepad::listen(gamepad, [gamepad](const js_event& value) {
    emit_gamepad_event(gamepad, value);
  });
}

void event_loop_start() {
  connection_listener::listen(
      &keep_reading_events,
      [](const connection_listener::ConnectionEvent& event) {
        std::string key = event.device_id;
        auto existingGamepad = gamepads.find(key);
        if (event.type == connection_listener::ConnectionEventType::CONNECTED) {
          if (existingGamepad != gamepads.end() &&
              existingGamepad->second.alive) {
            std::cout << "Existing gamepad found; skipping" << std::endl;
            return;
          }

          std::optional<gamepad::GamepadInfo> info =
              gamepad::get_gamepad_info(key);
          if (!info) {
            std::cerr << "Unable to open joystick for reading " << key
                      << std::endl;
            return;
          }

          std::cout << "Gamepad connected " << key << " - " << info->name
                    << std::endl;
          gamepads[key] = *info;
          emit_gamepad_connection_event(key, info->name, true);

          std::thread input_thread(process_connection_event, &gamepads[key]);
          input_thread.detach();
        } else {
          std::cout << "Gamepad disconnected " << key << std::endl;
          if (existingGamepad != gamepads.end()) {
            const std::string name = existingGamepad->second.name;
            existingGamepad->second.alive = false;
            gamepads.erase(existingGamepad);
            emit_gamepad_connection_event(key, name, false);
          }
        }
      });
}

static void gamepads_linux_plugin_dispose(GObject* object) {
  auto* self = GAMEPADS_LINUX_PLUGIN(object);
  delete self->rumble;
  self->rumble = nullptr;
  keep_reading_events = false;
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
