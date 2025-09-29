import { AsyncDuckDBDispatcher, WorkerResponseVariant, WorkerRequestVariant } from '../parallel';
import { DuckDB } from '../bindings/bindings_browser_eh';
import { DuckDBBindings } from '../bindings';
import { BROWSER_RUNTIME } from '../bindings/runtime_browser';
import { InstantiationProgress } from '../bindings/progress';
import { bindPort, isSharedWorker } from '../utils/shared_worker.js';

/** The duckdb worker API for web workers */
class WebWorker extends AsyncDuckDBDispatcher {
    requestPorts?: Map<MessagePort, { connCount: number }>;

    /** Post a response back to the main thread */
    protected postMessage(response: WorkerResponseVariant, transfer: ArrayBuffer[], port?: MessagePort) {
        // SharedWorker
        if (this.requestPorts) {
            for (const it of port ? [port] : this.requestPorts.keys()) it.postMessage(response, transfer);
        } else {
            globalThis.postMessage(response, transfer);
        }
    }

    /** Instantiate the wasm module */
    protected async instantiate(
        mainModuleURL: string,
        pthreadWorkerURL: string | null,
        progress: (p: InstantiationProgress) => void,
    ): Promise<DuckDBBindings> {
        const bindings = new DuckDB(this, BROWSER_RUNTIME, mainModuleURL, pthreadWorkerURL);
        return await bindings.instantiate(progress);
    }
}

/** Register the worker */
export function registerWorker(): void {
    const api = new WebWorker();
    if (isSharedWorker(self)) {
        console.log('DuckDB[EH] shared worker is starting ...');
        api.requestPorts = new Map();
        self.onconnect = async ({ ports, type }) => {
            const port = ports[0];
            const portMeta = { connCount: 0 };
            api.requestPorts!.set(port, portMeta);
            console.log(`DuckDB[EH] shared worker receives a connection: ${type}`);
            port.onmessage = async (event: MessageEvent<WorkerRequestVariant>) => {
                console.log(`DuckDB[EH] shared worker receives a message: ${event.type}`, event.data);
                portMeta.connCount++;
                api.requestPorts!.set(port, portMeta);
                bindPort(event.data, port);
                try {
                    await api.onMessage(event.data);
                } finally {
                    portMeta.connCount--;
                    if (portMeta.connCount <= 0) api.requestPorts?.delete(port);
                }
            };
            port.start();
        };
    } else {
        globalThis.onmessage = async (event: MessageEvent<WorkerRequestVariant>) => {
            await api.onMessage(event.data);
        };
    }
}

registerWorker();
