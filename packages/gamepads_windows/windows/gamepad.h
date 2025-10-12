
#include <map>
#include <winrt/Windows.Gaming.Input.h>
#include <wtypes.h>

using namespace winrt;
using namespace Windows::Gaming;

#include <windows.h>
#include <functional>
#include <iostream>
#include <list>
#include <map>
#include <optional>
#include <GameInput.h>

struct GamepadData {
  std::string id;
  std::string name;
  int num_buttons;
  bool stop_thead;
  bool alive;
};

struct Event {
  int time;
  std::string type;
  std::string key;
  double value;
};

class Gamepads {
 private:
  std::list<GamepadData*> gamepads;

  GameInputCallbackToken* deviceCallbackToken;
  //GameInputCallbackToken* readingCallbackToken;
  void read_gamepad(GamepadData* gamepad, IGameInputDevice* device);

  void on_gamepad_connected(IGameInputDevice* device);
  void on_gamepad_disconnected(IGameInputDevice* device);

 public:
  std::optional<std::function<void(GamepadData* gamepad, const Event& event)>>
      event_emitter;
  void init();
  void stop();
  std::list<GamepadData*> get_gamepads();
};

extern Gamepads gamepads;

std::optional<LRESULT> CALLBACK GamepadListenerProc(HWND hwnd,
                                                    UINT uMsg,
                                                    WPARAM wParam,
                                                    LPARAM lParam);