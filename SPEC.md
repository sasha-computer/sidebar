# Sidebar: macOS Desktop Dashboard

A permanent sidebar on the right edge of your external monitor showing everything you need at a glance. Built with **Svelte + Vite + Tailwind** running in a **Hammerspoon webview**.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    LG UltraFine 5K                      │
│                   (2560 x 1440 logical)                 │
│                                                         │
│  ┌─────────────────────────────┐  ┌──────────────────┐  │
│  │                             │  │                  │  │
│  │     App windows             │  │    Sidebar       │  │
│  │     (2260px usable)         │  │    (300px)       │  │
│  │                             │  │                  │  │
│  │  capslock+left = left half  │  │  hs.webview      │  │
│  │  capslock+right = right half│  │  always on top   │  │
│  │  (of the 2260px zone)       │  │  borderless      │  │
│  │                             │  │  non-activating  │  │
│  │                             │  │                  │  │
│  └─────────────────────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

When undocked (no external display), the sidebar disappears and capslock+left/right uses the full screen width.

## Tech Stack

| Layer | Tool | Why |
|-------|------|-----|
| UI | Svelte + Tailwind v4 | Your preferred framework, clean and reactive |
| Bundler | Vite (via Bun) | Fast HMR during dev, static build for prod |
| Host | Hammerspoon hs.webview | Native macOS webview, always-on-top, borderless |
| Data | Local APIs + scripts | Todoist API, macOS native commands, etc. |
| IPC | hs.webview.usercontent | JS <-> Lua message passing |

### Two Modes

1. **Dev mode**: Hammerspoon webview points at `http://localhost:5173` (Vite dev server). Hot reload works.
2. **Prod mode**: `bun run build` outputs to `dist/`. Hammerspoon loads `file:///path/to/dist/index.html`. No server needed.

## Hammerspoon Setup

### Installation

```fish
brew install --cask hammerspoon
```

Grant Accessibility permissions in System Settings > Privacy & Security > Accessibility.

### init.lua Structure

```
~/.hammerspoon/
├── init.lua              # Entry point, loads modules
├── sidebar.lua           # Sidebar webview management
└── windows.lua           # Window management (capslock splits)
```

### sidebar.lua - Key Concepts

```lua
-- Create a borderless, non-activating webview on the right edge
local screen = hs.screen.find("LG")
local frame = screen:frame()
local sidebarWidth = 300

local uc = hs.webview.usercontent.new("sidebar")
uc:setCallback(function(msg)
    -- Handle messages from Svelte app
    local body = msg.body
    if body.action == "completeTask" then
        -- Call todoist script, return result
    end
end)

local sidebar = hs.webview.new(
    { x = frame.x + frame.w - sidebarWidth, y = frame.y, w = sidebarWidth, h = frame.h },
    { developerExtrasEnabled = true },
    uc
)

sidebar:windowStyle({"borderless", "nonactivating"})
sidebar:level(hs.drawing.windowLevels.floating)  -- above normal windows
sidebar:behavior({"canJoinAllSpaces", "stationary"})  -- visible on all spaces
sidebar:allowTextEntry(true)  -- for quick notes input
sidebar:shadow(false)
sidebar:url("http://localhost:5173")  -- dev mode
-- sidebar:url("file://" .. os.getenv("HOME") .. "/Developer/experiments/2026-02-14-sidebar/dist/index.html")  -- prod
sidebar:show()
```

### Screen Watcher (auto show/hide on dock/undock)

```lua
local screenWatcher = hs.screen.watcher.new(function()
    local screens = hs.screen.allScreens()
    local hasExternal = false
    for _, s in ipairs(screens) do
        if s:name() == "LG UltraFine" then
            hasExternal = true
            break
        end
    end

    if hasExternal then
        showSidebar()
    else
        hideSidebar()
    end
end)
screenWatcher:start()
```

### Window Management (capslock + arrow keys)

Use Karabiner-Elements to remap CapsLock to F18 (or Hyper key). Then in Hammerspoon:

```lua
local sidebarVisible = true

local function getUsableFrame()
    local screen = hs.window.focusedWindow():screen()
    local frame = screen:frame()
    if sidebarVisible and screen:name() == "LG UltraFine" then
        frame.w = frame.w - 300  -- reserve sidebar space
    end
    return frame
end

-- Capslock (F18) + Left = left half
hs.hotkey.bind({"ctrl", "alt", "cmd", "shift"}, "left", function()
    local win = hs.window.focusedWindow()
    local f = getUsableFrame()
    win:setFrame({ x = f.x, y = f.y, w = f.w / 2, h = f.h })
end)

-- Capslock (F18) + Right = right half
hs.hotkey.bind({"ctrl", "alt", "cmd", "shift"}, "right", function()
    local win = hs.window.focusedWindow()
    local f = getUsableFrame()
    win:setFrame({ x = f.x + f.w / 2, y = f.y, w = f.w / 2, h = f.h })
end)

-- Capslock + Up = maximize (within usable area)
hs.hotkey.bind({"ctrl", "alt", "cmd", "shift"}, "up", function()
    local win = hs.window.focusedWindow()
    local f = getUsableFrame()
    win:setFrame(f)
end)
```

## JS <-> Lua Communication

### Svelte -> Hammerspoon (via usercontent message port)

```typescript
// In Svelte app
function sendToHammerspoon(action: string, data?: any) {
    try {
        window.webkit.messageHandlers.sidebar.postMessage({ action, ...data })
    } catch {
        // Running in browser dev mode, not in Hammerspoon
        console.log('[sidebar]', action, data)
    }
}
```

### Hammerspoon -> Svelte (via JavaScript injection)

```lua
-- Push data from Lua into the webview
sidebar:evaluateJavaScript(string.format(
    "window.__hammerspoon__.receive(%s)",
    hs.json.encode({ type = "screenChange", data = { external = true } })
))
```

```typescript
// In Svelte app - global receiver
window.__hammerspoon__ = {
    receive(msg: { type: string; data: any }) {
        // Dispatch to a Svelte store
        hammerspoonStore.set(msg)
    }
}
```

## Svelte App Structure

```
src/
├── App.svelte              # Main layout, scrollable column of widgets
├── app.css                 # Tailwind imports + global styles
├── lib/
│   ├── bridge.ts           # Hammerspoon IPC helpers
│   ├── stores.ts           # Svelte stores for widget data
│   └── types.ts            # TypeScript types
├── widgets/
│   ├── Calendar.svelte     # Date, mini cal, upcoming events
│   ├── Todoist.svelte      # Tasks from Todoist API
│   ├── Music.svelte        # Now playing (AppleScript -> Lua -> JS)
│   ├── Clipboard.svelte    # Recent clipboard history
│   ├── SystemStats.svelte  # CPU, MEM, Disk, Battery
│   ├── TopProcesses.svelte # Top 5 CPU consumers
│   ├── QuickNote.svelte    # Text input -> save to Obsidian
│   ├── Downloads.svelte    # Recent files in ~/Downloads
│   └── Screenshots.svelte  # Recent screenshots (thumbnails)
└── vite-env.d.ts
```

## Widget Specs

### 1. Calendar
- **Data**: `hs.calendar` or shell out to `icalBuddy` (brew install icalbuddy)
- Shows: today's date, mini month calendar, next 3-5 events
- Polls every 5 minutes
- Click event to open Calendar.app

### 2. Todoist
- **Data**: Todoist API v1 (you already have scripts + API key in 1Password)
- Shows: today's tasks (3-5 items)
- Actions: complete task (checkbox), tap to open in Todoist
- Polls every 2 minutes
- Uses the existing skill scripts or direct API calls from the Svelte app

### 3. Music (Now Playing)
- **Data**: Lua calls `hs.spotify` or `hs.applescript` for Music.app
- Shows: track name, artist, album art, playback controls
- Updates via polling or Hammerspoon push every 5s

### 4. Clipboard History
- **Data**: Lua uses `hs.pasteboard` to watch clipboard
- Shows: last 5 clipboard entries (truncated)
- Click to copy back to clipboard

### 5. System Stats
- **Data**: Lua calls shell commands (`top`, `sysctl`, `df`, `pmset`)
- Shows: CPU %, MEM %, Disk usage, Battery %
- Mini bar charts (Tailwind styled)
- Updates every 10s

### 6. Top Processes
- **Data**: `ps aux --sort=-%cpu | head -6`
- Shows: process name, CPU %, MEM
- Updates every 10s

### 7. Quick Note
- **Data**: Text input, saved via Lua to `~/Notes/` or Obsidian vault
- Simple text field + submit
- Sends content to Hammerspoon via message port

### 8. Downloads
- **Data**: `ls -t ~/Downloads | head -5`
- Shows: filename, size
- Click to reveal in Finder

### 9. Screenshots
- **Data**: Watch `~/Desktop` or CleanShot save directory for recent PNGs
- Shows: thumbnail grid (2x2 or 3 across)
- Click to open/preview

## Design

Following your taste preferences:

- **Dark background**: `#1e1e2e` (Catppuccin Mocha base) or similar
- **Muted text**: `#cdd6f4` (Catppuccin text)
- **One accent**: `#89b4fa` (Catppuccin blue) for active states
- **Berkeley Mono** for all text
- **Generous spacing** between widgets
- **Subtle separators** between sections (1px lines, low opacity)
- **No borders on widgets** -- just spacing and subtle backgrounds
- Smooth fade-in on load
- Lucide icons for section headers
- Scrollable with hidden scrollbar (webkit scrollbar styling)
- Each widget: icon + label header, then content below

## Implementation Plan

### Phase 1: Foundation (get it on screen)
1. Install Hammerspoon (`brew install --cask hammerspoon`)
2. Set up Karabiner-Elements for CapsLock -> Hyper key (if not already)
3. Write `~/.hammerspoon/init.lua` + `sidebar.lua` with basic webview
4. Scaffold Svelte app: `bun create vite sidebar-app --template svelte-ts`
5. Add Tailwind v4: `bun add -D @tailwindcss/vite tailwindcss`
6. Get "Hello Sidebar" rendering in the Hammerspoon webview
7. Set up the JS <-> Lua bridge (usercontent message port)

### Phase 2: Window management
8. Write `windows.lua` for capslock+arrow splits (aware of sidebar width)
9. Add screen watcher for dock/undock auto-show/hide
10. Test: sidebar appears on external, disappears on laptop only

### Phase 3: Widgets (one at a time)
11. Calendar widget (date + mini cal + events via icalBuddy)
12. Todoist widget (API calls, complete tasks)
13. System stats + top processes (shell commands via Lua)
14. Quick note (text input -> Obsidian)
15. Music (now playing via hs.spotify / AppleScript)
16. Clipboard history (hs.pasteboard watcher)
17. Downloads + Screenshots (file watching)

### Phase 4: Polish
18. Animations (fade in widgets, smooth transitions)
19. Error handling (API failures, offline states)
20. Prod build mode (file:// URL instead of localhost)
21. Auto-start (Hammerspoon launches at login, loads sidebar)

## Data Flow Patterns

### Pattern A: Lua-driven data (system stats, music, clipboard)
```
Hammerspoon timer (every Ns)
  -> Run shell command / call hs.* API
  -> sidebar:evaluateJavaScript("window.__hs__.receive(...)")
  -> Svelte store updates
  -> UI re-renders
```

### Pattern B: JS-driven data (Todoist, calendar)
```
Svelte onMount -> fetch() to API directly
  -> Update local store
  -> UI renders
(No Lua involvement needed for read-only API calls)
```

### Pattern C: JS actions -> Lua (complete task, open file, save note)
```
User clicks button in Svelte
  -> webkit.messageHandlers.sidebar.postMessage({action: "openFile", path: "..."})
  -> Lua callback fires
  -> hs.execute("open " .. path) or hs.urlevent.openURL(...)
```

## Key Decisions

1. **Svelte over React**: Your preference, cleaner code, easier to debug
2. **Single webview** (not two like the reference): Simpler. No need for a separate top bar since macOS already has a menu bar.
3. **300px width**: Matches the reference. On a 2560px wide display, leaves 2260px for apps -- still very usable.
4. **Floating level**: Above normal windows but below modals/menus. Doesn't steal focus thanks to `nonactivating`.
5. **Direct API calls from JS where possible**: For Todoist, calendar APIs -- no need to round-trip through Lua. Use Lua bridge only for things that need macOS access (files, clipboard, processes, window management).
6. **Polling over websockets**: Simpler. Most data doesn't need sub-second updates.
7. **icalBuddy for calendar**: Well-established CLI tool for reading macOS Calendar data. Alternative: direct EventKit via Lua.
8. **Karabiner for CapsLock**: Hammerspoon can't natively intercept CapsLock. Karabiner remaps it to F18 (or Hyper = ctrl+alt+cmd+shift), then Hammerspoon binds to that.

## Open Questions

- [ ] Do you already have Karabiner-Elements installed for CapsLock remapping?
- [ ] Which calendar app do you use? (Apple Calendar, Fantastical, etc.)
- [ ] Music app preference? (Spotify, Apple Music, etc.)
- [ ] Where do you want Quick Notes saved? (Obsidian vault path?)
- [ ] Any other widgets you want beyond the ones listed?
- [ ] CleanShot for screenshots? If so, what's the save directory?

## File Layout

```
~/Developer/experiments/2026-02-14-sidebar/
├── SPEC.md                     # This file
├── package.json                # Bun + Vite + Svelte
├── vite.config.ts
├── tailwind.config.ts
├── src/                        # Svelte app
│   ├── App.svelte
│   ├── app.css
│   ├── lib/
│   └── widgets/
├── dist/                       # Production build output
└── hammerspoon/                # Lua config (symlinked to ~/.hammerspoon/)
    ├── init.lua
    ├── sidebar.lua
    └── windows.lua
```
