import EventEmitter from "events";

export const eventBus = new EventEmitter();

// increase limit for many listeners
eventBus.setMaxListeners(50);