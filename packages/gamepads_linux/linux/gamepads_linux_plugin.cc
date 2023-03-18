#include "include/gamepads_linux/gamepads_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <string.h>
#include <pthread.h>

#include <iostream>
#include <map>
#include <memory>
#include <sstream>

#include "gamepad.h"

#define GAMEPADS_LINUX_PLUGIN(obj)                                       \
    (G_TYPE_CHECK_INSTANCE_CAST((obj), gamepads_linux_plugin_get_type(), \
                                GamepadsLinuxPlugin))

struct _GamepadsLinuxPlugin {
    GObject parent_instance;
};

G_DEFINE_TYPE(GamepadsLinuxPlugin, gamepads_linux_plugin, g_object_get_type())

static FlMethodChannel *channel;
bool _keep_reading_events = false;

static void emit_gamepad_event(std::string value) {
    if (channel) {
        g_autoptr(FlValue) map = fl_value_new_map();
        fl_value_set_string(map, "value", fl_value_new_string(value.c_str()));
        fl_method_channel_invoke_method(channel, "onGamepadEvent", map, nullptr, nullptr, nullptr);
    }
}

static void gamepads_linux_plugin_handle_method_call(GamepadsLinuxPlugin *self, FlMethodCall *method_call) {
    g_autoptr(FlMethodResponse) response = nullptr;
    int result;
    const gchar *method = fl_method_call_get_name(method_call);
    // FlValue *args = fl_method_call_get_args(method_call);

    if (strcmp(method, "getValue") == 0) {
        result = 42;
    } else {
        response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
        fl_method_call_respond(method_call, response, nullptr);
        return;
    }

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(result)));
    fl_method_call_respond(method_call, response, nullptr);
}

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call, gpointer user_data) {
    GamepadsLinuxPlugin *plugin = GAMEPADS_LINUX_PLUGIN(user_data);
    gamepads_linux_plugin_handle_method_call(plugin, method_call);
}

void gamepads_linux_plugin_register_with_registrar(FlPluginRegistrar *registrar) {
    GamepadsLinuxPlugin *plugin = GAMEPADS_LINUX_PLUGIN(g_object_new(gamepads_linux_plugin_get_type(), nullptr));

    g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
    channel = fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar), "xyz.luan/gamepads", FL_METHOD_CODEC(codec));

    fl_method_channel_set_method_call_handler(channel, method_call_cb, g_object_ref(plugin), g_object_unref);

    g_object_unref(plugin);
}

void* event_loop_start(void* arg) {
    gamepad::game_event_read_loop(
        "/dev/input/js0",
        &_keep_reading_events,
        [](const std::string& value) { emit_gamepad_event(value); }
    );
    return NULL;
}

static void gamepads_linux_plugin_dispose(GObject *object) {
    _keep_reading_events = false;
    G_OBJECT_CLASS(gamepads_linux_plugin_parent_class)->dispose(object);
}

static void gamepads_linux_plugin_class_init(GamepadsLinuxPluginClass *klass) {
    G_OBJECT_CLASS(klass)->dispose = gamepads_linux_plugin_dispose;
}

static void gamepads_linux_plugin_init(GamepadsLinuxPlugin *self) {
    _keep_reading_events =  true;

    pthread_t input_thread;
    int rc = pthread_create(&input_thread, NULL, event_loop_start, NULL);
    if (rc != 0) {
        std::cerr << "Error in pthread_create(): " << rc << std::endl;
    }
}