-- sidebar.lua
-- Manages the sidebar webview on the right edge of the external display

local M = {}

local SIDEBAR_WIDTH = 300
local EXTERNAL_DISPLAY = "LG UltraFine"
local DEV_URL = "http://localhost:5174"
local PROJECT_PATH = os.getenv("HOME") .. "/Developer/experiments/2026-02-14-sidebar"
local PROD_URL = "file://" .. PROJECT_PATH .. "/dist/index.html"
local NOTES_PATH = os.getenv("HOME") .. "/Documents/2026"

-- Use dev mode if the vite server is running, otherwise prod
local USE_DEV = true

local sidebar = nil
local screenWatcher = nil
local sidebarVisible = false

-- Timers for periodic data pushes
local systemTimer = nil
local spotifyTimer = nil
local clipboardTimer = nil
local downloadsTimer = nil
local screenshotsTimer = nil
local calendarTimer = nil

local lastClipboard = ""
local clipboardHistory = {}

-- ─── Helpers ───────────────────────────────────────────────

local function pushToWebview(msgType, data)
    if sidebar then
        local json = hs.json.encode({ type = msgType, data = data })
        sidebar:evaluateJavaScript(
            "window.__hammerspoon__ && window.__hammerspoon__.receive(" .. json .. ")"
        )
    end
end

local function findExternalScreen()
    for _, screen in ipairs(hs.screen.allScreens()) do
        if screen:name() == EXTERNAL_DISPLAY then
            return screen
        end
    end
    return nil
end

-- ─── Data Collectors ───────────────────────────────────────

local function collectSystemStats()
    -- CPU: use hs.host.cpuUsage
    local cpuUsage = hs.host.cpuUsage()
    local cpuPct = cpuUsage["overall"]["active"] or 0

    -- Memory
    local memInfo = hs.host.vmStat()
    local pageSize = memInfo.pageSize
    local totalPages = memInfo.memSize / pageSize
    local freePages = memInfo.pagesFree + memInfo.pagesInactive
    local usedPages = totalPages - freePages
    local memPct = (usedPages / totalPages) * 100
    local memUsedGB = string.format("%.1fGB", (usedPages * pageSize) / (1024^3))
    local memTotalGB = string.format("%.1fGB", memInfo.memSize / (1024^3))

    -- Disk
    local diskOutput = hs.execute("df -h / | tail -1 | awk '{print $3, $2, $5}'")
    local diskUsed, diskTotal, diskPct = diskOutput:match("(%S+)%s+(%S+)%s+(%d+)")
    diskPct = tonumber(diskPct) or 0

    -- Battery
    local battery = hs.battery.percentage() or 100
    local charging = hs.battery.isCharging() or false

    pushToWebview("systemStats", {
        cpu = cpuPct,
        mem = memPct,
        memUsed = memUsedGB,
        memTotal = memTotalGB,
        disk = diskPct,
        diskUsed = diskUsed or "",
        diskTotal = diskTotal or "",
        battery = battery,
        charging = charging,
    })
end

local function collectTopProcesses()
    local output = hs.execute("ps aux -r | head -6 | tail -5")
    local procs = {}
    for line in output:gmatch("[^\n]+") do
        local user, pid, cpu, mem, rest = line:match("(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(.*)")
        if cpu then
            -- Extract process name (last column, roughly)
            local name = rest:match("%S+$") or "unknown"
            -- Clean up path to just process name
            name = name:match("([^/]+)$") or name
            table.insert(procs, {
                name = name,
                cpu = tonumber(cpu) or 0,
                mem = string.format("%.1f%%", tonumber(mem) or 0),
            })
        end
    end
    pushToWebview("topProcesses", procs)
end

local function collectSpotify()
    if not hs.spotify.isRunning() then
        pushToWebview("nowPlaying", nil)
        return
    end

    local state = hs.spotify.getPlaybackState()
    if not state or state == "stopped" then
        pushToWebview("nowPlaying", nil)
        return
    end

    local track = hs.spotify.getCurrentTrack() or ""
    local artist = hs.spotify.getCurrentArtist() or ""
    local album = hs.spotify.getCurrentAlbum() or ""
    local pos = hs.spotify.getPosition() or 0
    local dur = hs.spotify.getDuration() or 0

    pushToWebview("nowPlaying", {
        track = track,
        artist = artist,
        album = album,
        artUrl = "",  -- Spotify doesn't expose art URL easily via hs.spotify
        playing = (state == "playing"),
        position = pos,
        duration = dur,
    })
end

local function collectClipboard()
    local current = hs.pasteboard.getContents() or ""
    if current ~= lastClipboard and current ~= "" then
        lastClipboard = current
        table.insert(clipboardHistory, 1, {
            text = current:sub(1, 200),
            timestamp = os.time(),
        })
        -- Keep last 10
        while #clipboardHistory > 10 do
            table.remove(clipboardHistory)
        end
    end
    pushToWebview("clipboard", clipboardHistory)
end

local function collectDownloads()
    local output = hs.execute('ls -t ~/Downloads | head -5')
    local files = {}
    for name in output:gmatch("[^\n]+") do
        if name ~= "" and not name:match("^%.") then
            local sizeOut = hs.execute('stat -f "%z" ~/Downloads/' .. hs.http.encodeForQuery(name) .. ' 2>/dev/null')
            local bytes = tonumber(sizeOut) or 0
            local size = ""
            if bytes > 1024 * 1024 * 1024 then
                size = string.format("%.1fGB", bytes / (1024^3))
            elseif bytes > 1024 * 1024 then
                size = string.format("%.1fMB", bytes / (1024^2))
            elseif bytes > 1024 then
                size = string.format("%.1fKB", bytes / 1024)
            else
                size = bytes .. "B"
            end
            table.insert(files, {
                name = name,
                size = size,
                path = os.getenv("HOME") .. "/Downloads/" .. name,
            })
        end
    end
    pushToWebview("downloads", files)
end

local function collectScreenshots()
    -- macOS default screenshots go to ~/Desktop with "Screenshot" prefix
    local output = hs.execute('ls -t ~/Desktop/Screenshot\\ *.png 2>/dev/null | head -6')
    local shots = {}
    for path in output:gmatch("[^\n]+") do
        if path ~= "" then
            local name = path:match("([^/]+)$") or path
            -- Convert to file:// URL for img src in webview
            local thumbnail = "file://" .. path
            table.insert(shots, {
                name = name,
                path = path,
                thumbnail = thumbnail,
            })
        end
    end
    pushToWebview("screenshots", shots)
end

local function collectCalendar()
    -- Use icalBuddy if available, otherwise skip
    local hasBuddy = hs.execute("which icalBuddy 2>/dev/null")
    if not hasBuddy or hasBuddy == "" then
        -- Fallback: no calendar data without icalBuddy
        pushToWebview("calendar", {})
        return
    end

    local output = hs.execute('icalBuddy -f -ea -nc -b "" -ss "" -ic "" eventsToday 2>/dev/null')
    local events = {}
    -- Basic parsing of icalBuddy output
    for line in output:gmatch("[^\n]+") do
        local title = line:match("^%s*(.+)$")
        if title and title ~= "" then
            table.insert(events, {
                title = title,
                start = "",
                ["end"] = "",
                allDay = false,
                calendar = "",
            })
        end
    end
    pushToWebview("calendar", events)
end

-- ─── Message Handler (JS -> Lua) ──────────────────────────

local function handleMessage(msg)
    local body = msg.body
    if not body or not body.action then return end

    local action = body.action

    if action == "openUrl" then
        hs.urlevent.openURL(body.url)
    elseif action == "openFile" then
        hs.execute('open "' .. body.path .. '"')
    elseif action == "revealFile" then
        hs.execute('open -R "' .. body.path .. '"')
    elseif action == "openFolder" then
        local path = body.path:gsub("^~", os.getenv("HOME"))
        hs.execute('open "' .. path .. '"')
    elseif action == "copyToClipboard" then
        hs.pasteboard.setContents(body.text)
    elseif action == "saveNote" then
        -- Save quick note to Obsidian vault
        local date = os.date("%Y-%m-%d")
        local time = os.date("%H:%M")
        local filepath = NOTES_PATH .. "/Quick Notes.md"
        local file = io.open(filepath, "a")
        if file then
            file:write("\n## " .. date .. " " .. time .. "\n\n" .. body.text .. "\n")
            file:close()
            hs.notify.new({ title = "Sidebar", informativeText = "Note saved" }):send()
        end
    elseif action == "musicToggle" then
        hs.spotify.playpause()
    elseif action == "musicNext" then
        hs.spotify.next()
    elseif action == "musicPrev" then
        hs.spotify.previous()
    end
end

-- ─── Create / Destroy Sidebar ──────────────────────────────

function M.show()
    if sidebar then return end

    local screen = findExternalScreen()
    if not screen then return end

    local frame = screen:frame()

    -- Create user content controller for JS <-> Lua messaging
    local uc = hs.webview.usercontent.new("sidebar")
    uc:setCallback(handleMessage)

    sidebar = hs.webview.new(
        {
            x = frame.x + frame.w - SIDEBAR_WIDTH,
            y = frame.y,
            w = SIDEBAR_WIDTH,
            h = frame.h,
        },
        { developerExtrasEnabled = true, javaScriptEnabled = true },
        uc
    )

    sidebar:windowStyle(hs.webview.windowMasks.borderless | hs.webview.windowMasks.nonactivating)
    sidebar:level(hs.drawing.windowLevels.floating)
    sidebar:behavior(hs.drawing.windowBehaviors.canJoinAllSpaces + hs.drawing.windowBehaviors.stationary)
    sidebar:allowTextEntry(true)
    sidebar:shadow(false)
    sidebar:alpha(1.0)

    -- Load the URL
    if USE_DEV then
        sidebar:url(DEV_URL)
    else
        sidebar:url(PROD_URL)
    end

    sidebar:show()
    sidebarVisible = true

    -- Inject Todoist API token (read from 1Password at Hammerspoon load time)
    -- Inject multiple times to catch page loads / reloads
    local function injectToken()
        if sidebar and TODOIST_TOKEN then
            sidebar:evaluateJavaScript(
                "window.__TODOIST_TOKEN__ = '" .. TODOIST_TOKEN .. "'"
            )
        end
    end
    hs.timer.doAfter(1, injectToken)
    hs.timer.doAfter(3, injectToken)
    hs.timer.doAfter(6, injectToken)

    -- Start data collection timers
    systemTimer = hs.timer.doEvery(10, function()
        collectSystemStats()
        collectTopProcesses()
    end)
    -- Initial push
    hs.timer.doAfter(3, function()
        collectSystemStats()
        collectTopProcesses()
        collectClipboard()
        collectDownloads()
        collectScreenshots()
        collectCalendar()
    end)

    spotifyTimer = hs.timer.doEvery(5, collectSpotify)
    clipboardTimer = hs.timer.doEvery(2, collectClipboard)
    downloadsTimer = hs.timer.doEvery(30, collectDownloads)
    screenshotsTimer = hs.timer.doEvery(30, collectScreenshots)
    calendarTimer = hs.timer.doEvery(300, collectCalendar)

    hs.notify.new({ title = "Sidebar", informativeText = "Sidebar visible" }):send()
end

function M.hide()
    if sidebar then
        sidebar:delete()
        sidebar = nil
    end
    sidebarVisible = false

    -- Stop timers
    if systemTimer then systemTimer:stop(); systemTimer = nil end
    if spotifyTimer then spotifyTimer:stop(); spotifyTimer = nil end
    if clipboardTimer then clipboardTimer:stop(); clipboardTimer = nil end
    if downloadsTimer then downloadsTimer:stop(); downloadsTimer = nil end
    if screenshotsTimer then screenshotsTimer:stop(); screenshotsTimer = nil end
    if calendarTimer then calendarTimer:stop(); calendarTimer = nil end
end

function M.toggle()
    if sidebarVisible then
        M.hide()
    else
        M.show()
    end
end

function M.isVisible()
    return sidebarVisible
end

function M.getWidth()
    return SIDEBAR_WIDTH
end

-- ─── Screen Watcher ────────────────────────────────────────

function M.startScreenWatcher()
    screenWatcher = hs.screen.watcher.new(function()
        local hasExternal = findExternalScreen() ~= nil
        if hasExternal and not sidebarVisible then
            M.show()
        elseif not hasExternal and sidebarVisible then
            M.hide()
        end
    end)
    screenWatcher:start()
end

function M.stopScreenWatcher()
    if screenWatcher then
        screenWatcher:stop()
        screenWatcher = nil
    end
end

return M
