-- Hammerspoon init.lua
-- Sidebar dashboard + window management

-- Enable IPC (required for `hs` CLI command)
require("hs.ipc")

-- Add project hammerspoon dir to package path
local projectPath = os.getenv("HOME") .. "/Developer/experiments/2026-02-14-sidebar/hammerspoon"
package.path = projectPath .. "/?.lua;" .. package.path

-- ─── Todoist Token ─────────────────────────────────────────
-- Read from 1Password at startup (cached globally for sidebar.lua)
local tokenHandle = io.popen(os.getenv("HOME") .. "/.pi/agent/skills/1password-vault/scripts/read-secret.sh 'Todoist API' credential 2>/dev/null")
if tokenHandle then
    TODOIST_TOKEN = tokenHandle:read("*a"):gsub("%s+$", "")
    tokenHandle:close()
    if TODOIST_TOKEN == "" then TODOIST_TOKEN = nil end
end

-- ─── Load Modules ──────────────────────────────────────────
local sidebar = require("sidebar")
local windows = require("windows")

-- ─── Auto-reload config on change ─────────────────────────
local configWatcher = hs.pathwatcher.new(projectPath, function(files)
    for _, file in ipairs(files) do
        if file:match("%.lua$") then
            hs.reload()
            return
        end
    end
end)
configWatcher:start()

-- ─── Start ─────────────────────────────────────────────────
sidebar.startScreenWatcher()

-- Show sidebar if external display is already connected
hs.timer.doAfter(1, function()
    local hasExternal = false
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:name() == "LG UltraFine" then
            hasExternal = true
            break
        end
    end
    if hasExternal then
        sidebar.show()
    end
end)

hs.notify.new({ title = "Hammerspoon", informativeText = "Config loaded" }):send()
