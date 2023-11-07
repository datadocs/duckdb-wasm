import { DuckDBDataProtocol, failWith, FileFlags, getDataProtocolName, OpenedFile } from './runtime';
import { OPFSFileHandle } from './opfs';
import { DuckDBModule } from './duckdb_module';
import type { BROWSER_RUNTIME } from './runtime_browser';

export function registerAsyncMethodsIntoBrowserRuntime(runtime: typeof BROWSER_RUNTIME) {
    runtime.openFileAsync = autoThrowWASMError(openFileAsync);
    return runtime;

    async function openFileAsync(mod: DuckDBModule, fileId: number, flags: FileFlags): Promise<number> {
        try {
            runtime._fileInfoCache.delete(fileId);
            const file = runtime.getFileInfo(mod, fileId);
            if (!file) throw `The file with id ${fileId} was not found`;
            if (file.dataProtocol === DuckDBDataProtocol.BROWSER_FSACCESS) {
                // OPFS
                const fileName = file.fileName;
                const handle: OPFSFileHandle = runtime._files!.get(fileName);
                if (!handle?.fileName) throw new Error(`Invalid file handle of the file "${fileName}"`);
                if (!handle.fileHandle) {
                    const dir = handle.dirHandle;
                    if (!dir) throw new Error(`Failed to open file handle "${fileName}" from an unknown directory`);
                    handle.fileHandle = await dir.getFileHandle(fileName, {
                        create: true,
                    });
                }
                if (!handle.file) handle.file = await handle.fileHandle.getFile();
                if (!handle.accessHandle) handle.accessHandle = await handle.fileHandle.createSyncAccessHandle();
                return new OpenedFile(handle.file.size, 0).getCppPointer(mod);
            } else {
                throw new Error(
                    `openFileAsync doesn't support the protocol: ${getDataProtocolName(file?.dataProtocol)}`,
                );
            }
        } catch (e: any) {
            failWith(mod, e.toString());
            return 1;
        }
        return 0;
    }

    type RuntimeFunc<ParamsType extends any[], ReturnType> = (
        mod: DuckDBModule,
        ...args: ParamsType
    ) => Promise<ReturnType>;
    function autoThrowWASMError<ParamsType extends any[], ReturnType>(
        fn: RuntimeFunc<ParamsType, ReturnType>,
    ): RuntimeFunc<ParamsType, ReturnType> {
        return async (...args) => {
            let result: any;
            try {
                result = await fn(...args);
            } catch (error: any) {
                let errMsg: string;
                if (typeof error === 'string') errMsg = error;
                else errMsg = error.message;
                if (typeof errMsg !== 'string' || !errMsg) errMsg = 'Unknown Internal Error';
                failWith(args[0], errMsg);
            }
            return result;
        };
    }
}
