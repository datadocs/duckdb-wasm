/**
 * check if current worker context is a shared worker context
 * @example `isSharedWorker(self)`
 */
export function isSharedWorker(_self: unknown): _self is SharedWorkerGlobalScope {
    if (_self && 'onconnect' in (_self as any)) return true;
    return false;
}

const BOUND_PORT = Symbol('BOUND_PORT');

/**
 * Save the {@link MessagePort} into the incoming message object, so the worker could use the corresponding port for the reply
 * (Because one shared worker could be connected by multiple browser tabs)
 */
export function bindPort<T extends Record<string, any>>(msg: T, port: MessagePort): T {
    return Object.assign(msg, { [BOUND_PORT]: port });
}
/**
 * Get saved {@link MessagePort} in the incoming message object for reply
 */
export function getBoundPort<T extends Record<string, any>>(msg: T): MessagePort | undefined {
    return msg ? (msg as any)[BOUND_PORT] : undefined;
}
