/**
 * Hammerspoon <-> Svelte bridge
 *
 * In Hammerspoon webview: uses webkit.messageHandlers for JS->Lua
 * In browser dev mode: logs to console as fallback
 */

type MessageHandler = (msg: { type: string; data: any }) => void

const listeners: MessageHandler[] = []

/** Send a message from JS to Hammerspoon (Lua) */
export function sendToLua(action: string, data?: Record<string, any>) {
  try {
    ;(window as any).webkit.messageHandlers.sidebar.postMessage({
      action,
      ...(data || {}),
    })
  } catch {
    console.log('[bridge -> lua]', action, data)
  }
}

/** Register a listener for messages from Hammerspoon */
export function onLuaMessage(handler: MessageHandler) {
  listeners.push(handler)
  return () => {
    const idx = listeners.indexOf(handler)
    if (idx >= 0) listeners.splice(idx, 1)
  }
}

/** Called by Hammerspoon via evaluateJavaScript */
function receive(msg: { type: string; data: any }) {
  for (const handler of listeners) {
    try {
      handler(msg)
    } catch (e) {
      console.error('[bridge] handler error:', e)
    }
  }
}

// Expose to global scope for Hammerspoon to call
;(window as any).__hammerspoon__ = { receive }

/** Check if running inside Hammerspoon webview */
export function isHammerspoon(): boolean {
  try {
    return !!(window as any).webkit?.messageHandlers?.sidebar
  } catch {
    return false
  }
}
