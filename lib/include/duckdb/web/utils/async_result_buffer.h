#ifndef INCLUDE_DUCKDB_WEB_UTILS_ASYNC_RESULT_BUFFER_H_
#define INCLUDE_DUCKDB_WEB_UTILS_ASYNC_RESULT_BUFFER_H_

#include <emscripten.h>

#include <cstdint>

#include "duckdb/web/debug.h"

namespace duckdb {
namespace web {

uint8_t* PrepareAsyncResultBuffer(uint32_t result_size);

/// @brief
/// @param async_result_buffer
/// @return `false` represents that no any async result
bool WaitForAsyncResultBufferReady(const uint8_t* async_result_buffer);

uint32_t GetUInt32FromAsyncResultBuffer(const uint8_t* async_result_buffer);

void DestroyAsyncResultBuffer(uint8_t* async_result_buffer);

}  // namespace web
}  // namespace duckdb

#endif
