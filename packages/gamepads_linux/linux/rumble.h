#pragma once

#include <dirent.h>
#include <fcntl.h>
#include <linux/input.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <map>
#include <string>

// jsN is input-only. Open its sibling eventN to upload a kernel-timed effect.
class GamepadRumble {
 public:
  ~GamepadRumble() {
    while (!effects_.empty())
      Stop(effects_.begin()->first);
  }
  bool Has(const std::string& id) {
    const int fd = Open(id);
    if (fd < 0)
      return false;
    close(fd);
    return true;
  }
  bool Set(const std::string& id, double low, double high, int milliseconds) {
    if (!(low >= 0 && low <= 1 && high >= 0 && high <= 1) || milliseconds < 0 ||
        milliseconds > 30000)
      return false;
    if (milliseconds == 0 || (low == 0 && high == 0))
      return Stop(id);
    auto it = effects_.find(id);
    if (it == effects_.end()) {
      const int fd = Open(id);
      if (fd < 0)
        return false;
      it = effects_.emplace(id, Effect{fd, -1}).first;
    }
    ff_effect effect{};
    effect.type = FF_RUMBLE;
    effect.id = static_cast<short>(it->second.effect);
    effect.u.rumble.strong_magnitude = static_cast<__u16>(low * 65535);
    effect.u.rumble.weak_magnitude = static_cast<__u16>(high * 65535);
    effect.replay.length = static_cast<__u16>(milliseconds);
    if (ioctl(it->second.fd, EVIOCSFF, &effect) < 0) {
      Stop(id);
      return false;
    }
    it->second.effect = effect.id;
    input_event play{};
    play.type = EV_FF;
    play.code = static_cast<__u16>(effect.id);
    play.value = 1;
    if (write(it->second.fd, &play, sizeof(play)) != sizeof(play)) {
      Stop(id);
      return false;
    }
    return true;
  }
  bool Stop(const std::string& id) {
    const auto it = effects_.find(id);
    if (it == effects_.end())
      return Has(id);
    if (it->second.effect >= 0) {
      input_event stop{};
      stop.type = EV_FF;
      stop.code = static_cast<__u16>(it->second.effect);
      stop.value = 0;
      const auto ignored = write(it->second.fd, &stop, sizeof(stop));
      (void)ignored;
      ioctl(it->second.fd, EVIOCRMFF, it->second.effect);
    }
    close(it->second.fd);
    effects_.erase(it);
    return true;
  }

 private:
  struct Effect {
    int fd;
    int effect;
  };
  std::map<std::string, Effect> effects_;
  static int Open(const std::string& id) {
    const std::string prefix = "/dev/input/js";
    if (id.compare(0, prefix.size(), prefix) != 0 ||
        id.size() == prefix.size() ||
        id.find_first_not_of("0123456789", prefix.size()) != std::string::npos)
      return -1;
    const auto base = "/sys/class/input/" + id.substr(11) + "/device";
    DIR* directory = opendir(base.c_str());
    if (!directory)
      return -1;
    int found = -1;
    while (const auto* item = readdir(directory)) {
      const std::string name(item->d_name);
      if (name.compare(0, 5, "event") != 0)
        continue;
      const int fd =
          open(("/dev/input/" + name).c_str(), O_RDWR | O_NONBLOCK | O_CLOEXEC);
      if (fd < 0)
        continue;
      unsigned long bits[(FF_MAX + 8 * sizeof(unsigned long)) /
                         (8 * sizeof(unsigned long))]{};
      if (ioctl(fd, EVIOCGBIT(EV_FF, sizeof(bits)), bits) >= 0 &&
          (bits[FF_RUMBLE / (8 * sizeof(unsigned long))] &
           (1UL << (FF_RUMBLE % (8 * sizeof(unsigned long)))))) {
        found = fd;
        break;
      }
      close(fd);
    }
    closedir(directory);
    return found;
  }
};
