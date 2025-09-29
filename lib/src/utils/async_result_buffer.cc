#include "duckdb/web/utils/async_result_buffer.h"

#include <emscripten.h>

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>


namespace duckdb {
namespace web {

uint8_t* PrepareAsyncResultBuffer(uint32_t result_size) {
#ifdef EMSCRIPTEN
    auto buf = (uint8_t*)malloc(1 + result_size);
    buf[0] = 0;  // INIT_STATE
    return buf;
#else
    return nullptr;
#endif
}

bool WaitForAsyncResultBufferReady(const uint8_t* async_result_buffer) {
#ifdef EMSCRIPTEN
    if (!async_result_buffer) return false;
    if (async_result_buffer[0] != 2)  // ING_STATE
        return false;

    console_log("waiting for async buffer ready");
    uint32_t loop_times = 0;
    bool printed_warnings = false;
    while (1) {
        loop_times++;
        if(loop_times > 1000) {
            printed_warnings = true;
            console_log("warning: more than %u ms have been waited", loop_times);
        }
        if (async_result_buffer[0] == 1) break;  // FINISHED_STATE
        emscripten_sleep(1);
    }
    console_log("waited %u ms for async buffer ready", loop_times);
    return true;
#else
    return false;

#endif
}

uint32_t GetUInt32FromAsyncResultBuffer(const uint8_t* async_result_buffer) {
#ifdef EMSCRIPTEN
    uint32_t result = *reinterpret_cast<const uint32_t*>(async_result_buffer + sizeof(uint8_t));
    return result;
#else
    return 0;
#endif
}

void DestroyAsyncResultBuffer(uint8_t* async_result_buffer) {
    if (async_result_buffer) free(async_result_buffer);
}

}  // namespace web
}  // namespace duckdb
