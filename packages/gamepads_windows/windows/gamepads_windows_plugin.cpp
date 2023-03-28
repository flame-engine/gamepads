#include "gamepads_windows_plugin.h"

#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>

#include <memory>
#include <sstream>

struct GamepadInfo {
	std::string device_id;
	std::string name;
	int file_descriptor;
	bool alive;
};

bool keep_reading_events = false;
std::map<std::string, GamepadInfo> gamepads = {};

namespace gamepads_windows {
	void GamepadsWindowsPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarWindows* registrar
	) {
		auto channel =
			std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
				registrar->messenger(),
				"xyz.luan/gamepads",
				&flutter::StandardMethodCodec::GetInstance()
			);

		auto plugin = std::make_unique<GamepadsWindowsPlugin>();

		channel->SetMethodCallHandler(
			[plugin_pointer = plugin.get()](const auto& call, auto result) {
				plugin_pointer->HandleMethodCall(call, std::move(result));
			}
		);

		registrar->AddPlugin(std::move(plugin));
	}

	GamepadsWindowsPlugin::GamepadsWindowsPlugin() {}

	GamepadsWindowsPlugin::~GamepadsWindowsPlugin() {}

	void GamepadsWindowsPlugin::HandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
	) {
		if (method_call.method_name().compare("listGamepads") == 0) {
			flutter::EncodableList list;
			for (auto [device_id, gamepad] : gamepads) {
				flutter::EncodableMap map;
				map[flutter::EncodableValue("id")] = flutter::EncodableValue(device_id);
				map[flutter::EncodableValue("name")] = flutter::EncodableValue(gamepad.name);
				list.push_back(flutter::EncodableValue(map));
			}
			result->Success(flutter::EncodableValue(list));
		}
		else {
			result->NotImplemented();
		}
	}
}
