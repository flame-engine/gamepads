#include <GameInput.h>
#include <windows.h>

#include <chrono>
#include <condition_variable>
#include <cstdlib>
#include <mutex>

// Substitute only the GameInput calls used by rumble.h. The production header
// and its real deadline worker run unchanged; no physical controller is needed.
struct TestDevice {
  GameInputDeviceInfo info{};
  std::mutex mutex;
  std::condition_variable changed;
  GameInputRumbleParams last{};
  unsigned calls = 0;
  unsigned references = 0;

  const GameInputDeviceInfo* GetDeviceInfo() { return &info; }
  void AddRef() { ++references; }
  void Release() { --references; }
  void SetRumbleState(const GameInputRumbleParams* params) {
    // GameInput 3.3 can dereference a null stop parameter. Reject it even when
    // it comes from the worker, disconnect callback, or destructor.
    if (!params) std::abort();
    std::lock_guard<std::mutex> lock(mutex);
    last = *params;
    ++calls;
    changed.notify_all();
  }
  bool WaitForZero(unsigned minimum_calls) {
    std::unique_lock<std::mutex> lock(mutex);
    return changed.wait_for(lock, std::chrono::seconds(2), [&] {
      return calls >= minimum_calls && last.lowFrequency == 0 &&
             last.highFrequency == 0 && last.leftTrigger == 0 &&
             last.rightTrigger == 0;
    });
  }
};

struct TestInput {
  using Callback = void (*)(GameInputCallbackToken, void*, TestDevice*,
                            uint64_t, GameInputDeviceStatus,
                            GameInputDeviceStatus);
  TestDevice device;
  Callback callback = nullptr;
  void* context = nullptr;
  HRESULT RegisterDeviceCallback(TestDevice*, GameInputKind,
                                 GameInputDeviceStatus,
                                 GameInputEnumerationKind, void* owner,
                                 Callback notify,
                                 GameInputCallbackToken* token) {
    context = owner;
    callback = notify;
    *token = 1;
    Notify(GameInputDeviceConnected);
    return S_OK;
  }
  void Notify(GameInputDeviceStatus status) {
    callback(1, context, &device, 0, status, GameInputDeviceNoStatus);
  }
  void UnregisterCallback(GameInputCallbackToken, uint64_t) {}
  void Release() {}
};

static TestInput input;
static HRESULT TestCreate(TestInput** result) {
  *result = &input;
  return S_OK;
}

#define IGameInputDevice TestDevice
#define IGameInput TestInput
#define GameInputCreate TestCreate
#include "../rumble.h"
#undef GameInputCreate
#undef IGameInput
#undef IGameInputDevice

int main() {
  input.device.info.supportedRumbleMotors =
      GameInputRumbleLowFrequency | GameInputRumbleHighFrequency;
  const std::string id(APP_LOCAL_DEVICE_ID_SIZE * 2, '0');
  {
    GamepadRumble rumble;
    if (!rumble.Has(id) || !rumble.Set(id, 0.5, 0.5, 50)) return 1;
    if (!input.device.WaitForZero(2)) return 2;  // Native expiry.
    if (!rumble.Set(id, 0.5, 0.5, 0)) return 3;
    if (!input.device.WaitForZero(3)) return 4;  // Zero duration.
    if (!rumble.Set(id, 0, 0, 30000)) return 5;
    if (!input.device.WaitForZero(4)) return 6;  // Explicit stop.
    if (!rumble.Set(id, 0.5, 0.5, 30000)) return 7;
    input.Notify(GameInputDeviceNoStatus);
    if (!input.device.WaitForZero(6) || rumble.Has(id)) return 8;
    input.Notify(GameInputDeviceConnected);
    if (!rumble.Set(id, 0.5, 0.5, 30000)) return 9;
  }
  if (!input.device.WaitForZero(8) || input.device.references != 0) return 10;
  return 0;
}
