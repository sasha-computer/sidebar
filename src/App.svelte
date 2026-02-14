<script lang="ts">
  import './app.css'
  import './lib/bridge'
  import { onLuaMessage } from './lib/bridge'
  import {
    systemStats,
    topProcesses,
    nowPlaying,
    clipboardHistory,
    calendarEvents,
    recentDownloads,
    recentScreenshots,
  } from './lib/stores'

  import Calendar from './widgets/Calendar.svelte'
  import Todoist from './widgets/Todoist.svelte'
  import Music from './widgets/Music.svelte'
  import Clipboard from './widgets/Clipboard.svelte'
  import SystemStats from './widgets/SystemStats.svelte'
  import TopProcesses from './widgets/TopProcesses.svelte'
  import QuickNote from './widgets/QuickNote.svelte'
  import Downloads from './widgets/Downloads.svelte'
  import Screenshots from './widgets/Screenshots.svelte'

  // Route incoming Lua messages to the right store
  onLuaMessage((msg) => {
    switch (msg.type) {
      case 'systemStats':
        systemStats.set(msg.data)
        break
      case 'topProcesses':
        topProcesses.set(msg.data)
        break
      case 'nowPlaying':
        nowPlaying.set(msg.data)
        break
      case 'clipboard':
        clipboardHistory.set(msg.data)
        break
      case 'calendar':
        calendarEvents.set(msg.data)
        break
      case 'downloads':
        recentDownloads.set(msg.data)
        break
      case 'screenshots':
        recentScreenshots.set(msg.data)
        break
    }
  })
</script>

<div class="h-screen overflow-y-auto px-4 py-4 space-y-5">
  <Calendar />
  <div class="h-px bg-overlay"></div>

  <Todoist />
  <div class="h-px bg-overlay"></div>

  <Music />
  <div class="h-px bg-overlay"></div>

  <Clipboard />
  <div class="h-px bg-overlay"></div>

  <Screenshots />
  <div class="h-px bg-overlay"></div>

  <Downloads />
  <div class="h-px bg-overlay"></div>

  <QuickNote />
  <div class="h-px bg-overlay"></div>

  <SystemStats />
  <div class="h-px bg-overlay"></div>

  <TopProcesses />

  <!-- Bottom spacer -->
  <div class="h-4"></div>
</div>
