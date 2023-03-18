#include <memory>
#include <string>
#include <stdexcept>

// TODO(luan): temporary polyfill for std format bc flutter doesn't seem to support it
// will remove once we have a data structure for events anyway
const std::string string_format(const char * const zcFormat, ...);

bool starts_with(const std::string& string, const std::string& prefix);