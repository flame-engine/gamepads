#include <dirent.h>
#include <fcntl.h>
#include <linux/input.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <cstring>

// Exercise cached-descriptor recovery without requiring physical evdev access.
static int opened = 0;
static int closed = 0;
static bool disconnected = false;
static bool reject_all = false;
static bool listed = false;
static DIR* TestOpenDir(const char*) {
  listed = false;
  return reinterpret_cast<DIR*>(1);
}
static dirent* TestReadDir(DIR*) {
  static dirent entry{};
  if (listed)
    return nullptr;
  listed = true;
  std::strcpy(entry.d_name, "event0");
  return &entry;
}
static int TestCloseDir(DIR*) {
  return 0;
}
static int TestOpen(const char*, int) {
  return ++opened;
}
static int TestClose(int) {
  ++closed;
  return 0;
}
static ssize_t TestWrite(int, const void*, size_t size) {
  return size;
}
static int TestIoctl(int fd, unsigned long request, void* argument) {
  if (request == EVIOCSFF) {
    if (reject_all || (disconnected && fd == 1))
      return -1;
    static_cast<ff_effect*>(argument)->id = 0;
    return 0;
  }
  auto* bits = static_cast<unsigned long*>(argument);
  bits[FF_RUMBLE / (8 * sizeof(unsigned long))] |=
      1UL << (FF_RUMBLE % (8 * sizeof(unsigned long)));
  return 0;
}
static int TestIoctl(int, unsigned long, int) {
  return 0;
}

#define opendir TestOpenDir
#define readdir TestReadDir
#define closedir TestCloseDir
#define open TestOpen
#define close TestClose
#define write TestWrite
#define ioctl TestIoctl
#include "../rumble.h"
#undef ioctl
#undef write
#undef close
#undef open
#undef closedir
#undef readdir
#undef opendir

int main() {
  GamepadRumble rumble;
  if (!rumble.Set("/dev/input/js0", 0.5, 0.5, 500) || opened != 1)
    return 1;
  disconnected = true;
  if (!rumble.Set("/dev/input/js0", 0.5, 0.5, 500))
    return 2;
  if (opened != 2 || closed != 1)
    return 3;
  // A persistent failure retries a cached descriptor once, then gives up.
  reject_all = true;
  if (rumble.Set("/dev/input/js0", 0.5, 0.5, 500))
    return 4;
  if (opened != 3 || closed != 3)
    return 5;
  if (rumble.Set("/dev/input/js0", 0.5, 0.5, 500))
    return 6;
  return opened == 4 && closed == 4 ? 0 : 7;
}
