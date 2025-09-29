import { DuckDBModule } from '../bindings/duckdb_module.js';

/**
 * Enum representing the status of an asynchronous task.
 */
export const enum AsyncTaskStatus {
    INIT = 0,
    FINISHED = 1,
    PENDING = 2,
}

/**
 * Writes the PENDING status byte into the first position of the async task result buffer.
 * This indicates that the task is not yet complete.
 *
 * @param resultBuf - The pointer to the result buffer in the heap.
 */
export function writePendingByteIntoAsyncTaskResult(mod: Pick<DuckDBModule, 'HEAPU8'>, resultBuf: number | undefined) {
    if (!resultBuf) throw new Error(`No async result buffer provided`);
    if (mod.HEAPU8[resultBuf] !== AsyncTaskStatus.INIT)
        throw new Error(`The async result buffer is not at INIT status`);
    mod.HEAPU8[resultBuf] = AsyncTaskStatus.PENDING;
}

/**
 * Writes a 32-bit unsigned integer result into the async task result buffer starting from the second byte,
 * in little-endian byte order, and sets the first byte to FINISHED status.
 *
 * @param resultBuf - The pointer to the result buffer in the heap.
 * @param result - The 32-bit unsigned integer result to write.
 */
export function writeAsyncTaskUInt32Result(
    mod: Pick<DuckDBModule, 'HEAPU8'>,
    resultBuf: number | undefined,
    result: number,
) {
    if (!resultBuf) throw new Error(`No async result buffer provided`);
    if (mod.HEAPU8[resultBuf] !== AsyncTaskStatus.PENDING)
        throw new Error(`The async result buffer is not at PENDING status`);

    // Write the least significant byte (LSB) at offset +1
    mod.HEAPU8[resultBuf + 1] = result & 0xff;
    result >>= 8;

    mod.HEAPU8[resultBuf + 2] = result & 0xff;
    result >>= 8;

    mod.HEAPU8[resultBuf + 3] = result & 0xff;
    result >>= 8;

    mod.HEAPU8[resultBuf + 4] = result & 0xff;

    mod.HEAPU8[resultBuf] = AsyncTaskStatus.FINISHED;
}
