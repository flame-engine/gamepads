#pragma once

#include <windows.h>
#include <GameInput.h>
#include <chrono>
#include <condition_variable>
#include <iomanip>
#include <map>
#include <mutex>
#include <sstream>
#include <thread>

// Owns device references independently of input polling. No detached work may
// outlive this object, and each motor command has a native expiry.
class GamepadRumble {
 public:
  GamepadRumble() {
    if (FAILED(GameInputCreate(&input_)) || !input_)
      return;
    const auto hr = input_->RegisterDeviceCallback(
        nullptr, GameInputKindGamepad, GameInputDeviceConnected,
        GameInputBlockingEnumeration, this,
        [](GameInputCallbackToken, void* context, IGameInputDevice* device,
           uint64_t, GameInputDeviceStatus status, GameInputDeviceStatus) {
          static_cast<GamepadRumble*>(context)->OnDevice(device, status);
        },
        &token_);
    if (FAILED(hr)) {
      input_->Release();
      input_ = nullptr;
      return;
    }
    worker_ = std::thread([this] { Expire(); });
  }

  ~GamepadRumble() {
    if (input_ && token_)
      input_->UnregisterCallback(token_, UINT64_MAX);
    {
      std::lock_guard<std::mutex> lock(mutex_);
      stopping_ = true;
    }
    changed_.notify_all();
    if (worker_.joinable())
      worker_.join();
    for (auto& item : devices_) {
      Stop(item.second.device);
      item.second.device->Release();
    }
    if (input_)
      input_->Release();
  }

  bool Has(const std::string& id) {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto it = devices_.find(id);
    return it != devices_.end() && Supported(it->second.device);
  }

  bool Set(const std::string& id, double low, double high, int milliseconds) {
    if (!(low >= 0 && low <= 1 && high >= 0 && high <= 1) || milliseconds < 0 ||
        milliseconds > 30000)
      return false;
    std::lock_guard<std::mutex> lock(mutex_);
    const auto it = devices_.find(id);
    if (it == devices_.end() || !Supported(it->second.device))
      return false;
    auto& entry = it->second;
    const bool stop = milliseconds == 0 || (low == 0 && high == 0);
    GameInputRumbleParams params{};
    if (!stop) {
      params.lowFrequency = static_cast<float>(low);
      params.highFrequency = static_cast<float>(high);
    }
    entry.device->SetRumbleState(&params);
    entry.active = !stop;
    entry.until = Clock::now() + std::chrono::milliseconds(milliseconds);
    changed_.notify_all();
    return true;
  }

 private:
  using Clock = std::chrono::steady_clock;
  struct Entry {
    IGameInputDevice* device;
    bool active = false;
    Clock::time_point until{};
  };
  static void Stop(IGameInputDevice* device) {
    // Some GameInput redistributables dereference null rumble parameters.
    // Always send an explicit zero state, including trigger motors.
    const GameInputRumbleParams zero{};
    device->SetRumbleState(&zero);
  }
  static bool Supported(IGameInputDevice* device) {
    const auto* info = device->GetDeviceInfo();
    return info &&
           (info->supportedRumbleMotors &
            (GameInputRumbleLowFrequency | GameInputRumbleHighFrequency)) != 0;
  }
  void OnDevice(IGameInputDevice* device, GameInputDeviceStatus status) {
    const auto* info = device->GetDeviceInfo();
    if (!info)
      return;
    std::ostringstream id;
    id << std::hex << std::setfill('0');
    for (const auto byte : info->deviceId.value)
      id << std::setw(2) << static_cast<int>(byte);
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = devices_.find(id.str());
    if (it != devices_.end()) {
      Stop(it->second.device);
      it->second.device->Release();
      devices_.erase(it);
    }
    if (status & GameInputDeviceConnected) {
      device->AddRef();
      devices_.emplace(id.str(), Entry{device});
    }
    changed_.notify_all();
  }
  void Expire() {
    std::unique_lock<std::mutex> lock(mutex_);
    while (!stopping_) {
      auto next = (Clock::time_point::max)();
      for (auto& item : devices_) {
        auto& entry = item.second;
        if (!entry.active)
          continue;
        if (entry.until <= Clock::now()) {
          Stop(entry.device);
          entry.active = false;
        } else if (entry.until < next) {
          next = entry.until;
        }
      }
      if (next == (Clock::time_point::max)())
        changed_.wait(lock);
      else
        changed_.wait_until(lock, next);
    }
  }
  IGameInput* input_ = nullptr;
  GameInputCallbackToken token_{};
  std::mutex mutex_;
  std::condition_variable changed_;
  std::map<std::string, Entry> devices_;
  std::thread worker_;
  bool stopping_ = false;
};
