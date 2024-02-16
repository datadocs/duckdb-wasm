import DuckDBWasm from './duckdb-mvp.js';
import { DuckDBModule } from './duckdb_module';
import { DuckDBBindingsBase } from './bindings_base';
import type { DuckDBRuntime } from './runtime';
import { Logger } from '../log';
import fs from 'fs';

declare global {
    // eslint-disable-next-line no-var
    var DUCKDB_RUNTIME: DuckDBRuntime;
}

/** DuckDB bindings for node.js */
export class DuckDBNodeBindings extends DuckDBBindingsBase {
    /** The path of the wasm module */
    protected readonly mainModulePath: string;
    /** The path of the pthread worker script */
    protected readonly pthreadWorkerPath: string | null;

    /** Constructor */
    public constructor(
        logger: Logger,
        runtime: DuckDBRuntime,
        mainModulePath: string,
        pthreadWorkerPath: string | null,
    ) {
        super(logger, runtime);
        this.mainModulePath = mainModulePath;
        this.pthreadWorkerPath = pthreadWorkerPath;
    }

    /** Locate a file */
    protected locateFile(path: string, prefix: string): string {
        if (path.endsWith('.wasm')) {
            return this.mainModulePath;
        }
        if (path.endsWith('.worker.js')) {
            if (!this.pthreadWorkerPath) {
                throw new Error('Missing DuckDB worker path!');
            }
            return this.pthreadWorkerPath!;
        }
        throw new Error(`WASM instantiation requested unexpected file: prefix=${prefix} path=${path}`);
    }

    /** Instantiate the wasm module */
    protected instantiateWasm(
        // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
        imports: any,
        success: (instance: WebAssembly.Instance, module: WebAssembly.Module) => void,
    ): Emscripten.WebAssemblyExports {
        globalThis.DUCKDB_RUNTIME = {} as any;
        for (const func of Object.getOwnPropertyNames(this._runtime)) {
            if (func == 'constructor') continue;
            const runtime = globalThis.DUCKDB_RUNTIME as any;
            runtime[func] = Object.getOwnPropertyDescriptor(this._runtime, func)!.value;
        }
        const buf = fs.readFileSync(this.mainModulePath);
        WebAssembly.instantiate(buf, imports).then(output => {
            success(output.instance, output.module);
        });
        return [];
    }

    /** Instantiate the bindings */
    protected instantiateImpl(moduleOverrides: Partial<DuckDBModule>): Promise<DuckDBModule> {
        return DuckDBWasm({
            ...moduleOverrides,
            instantiateWasm: this.instantiateWasm.bind(this),
        });
    }
}
