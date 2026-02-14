-- windows.lua
-- Window management with Hyper key (CapsLock via Karabiner)
-- Aware of sidebar width when on external display

local sidebar = require("sidebar")

local M = {}

-- Hyper key = ctrl + alt + cmd + shift (mapped from CapsLock via Karabiner)
local hyper = { "ctrl", "alt", "cmd", "shift" }

-- Get the usable frame (excluding sidebar if visible on external)
local function getUsableFrame(win)
    local screen = win:screen()
    local frame = screen:frame()

    if sidebar.isVisible() and screen:name() == "LG UltraFine" then
        frame.w = frame.w - sidebar.getWidth()
    end

    return frame
end

-- ─── Splits ────────────────────────────────────────────────

-- Hyper + Left = left half
hs.hotkey.bind(hyper, "left", function()
    local win = hs.window.focusedWindow()
    if not win then return end
    local f = getUsableFrame(win)
    win:setFrame({
        x = f.x,
        y = f.y,
        w = f.w / 2,
        h = f.h,
    })
end)

-- Hyper + Right = right half
hs.hotkey.bind(hyper, "right", function()
    local win = hs.window.focusedWindow()
    if not win then return end
    local f = getUsableFrame(win)
    win:setFrame({
        x = f.x + f.w / 2,
        y = f.y,
        w = f.w / 2,
        h = f.h,
    })
end)

-- Hyper + Up = maximize (within usable area)
hs.hotkey.bind(hyper, "up", function()
    local win = hs.window.focusedWindow()
    if not win then return end
    local f = getUsableFrame(win)
    win:setFrame(f)
end)

-- Hyper + Down = center (60% width, full height)
hs.hotkey.bind(hyper, "down", function()
    local win = hs.window.focusedWindow()
    if not win then return end
    local f = getUsableFrame(win)
    local w = f.w * 0.6
    win:setFrame({
        x = f.x + (f.w - w) / 2,
        y = f.y,
        w = w,
        h = f.h,
    })
end)

-- Hyper + Return = full screen toggle
hs.hotkey.bind(hyper, "return", function()
    local win = hs.window.focusedWindow()
    if not win then return end
    win:toggleFullScreen()
end)

-- Hyper + S = toggle sidebar
hs.hotkey.bind(hyper, "s", function()
    sidebar.toggle()
end)

return M
