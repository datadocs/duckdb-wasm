#include "emscripten/console.h"

#ifndef CONSOLE_LOG_MAX
#define CONSOLE_LOG_MAX 16384
#endif

#ifndef init_console_log
#define init_console_log()                          \
    const char* _clog_pre = ">>> WASM >>> ";        \
    const size_t _clog_pre_len = strlen(_clog_pre); \
    char _clog_buff[CONSOLE_LOG_MAX];               \
    strcpy(_clog_buff, _clog_pre);                  \
    char* _clog_buff_main = _clog_buff + _clog_pre_len;

#endif

#ifndef console_log
#define console_log(...)                                                         \
    snprintf(_clog_buff_main, CONSOLE_LOG_MAX - _clog_pre_len - 1, __VA_ARGS__); \
    emscripten_console_log(_clog_buff)
#endif
