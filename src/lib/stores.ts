import { writable } from 'svelte/store'

// System stats pushed from Hammerspoon
export const systemStats = writable<{
  cpu: number
  mem: number
  memUsed: string
  memTotal: string
  disk: number
  diskUsed: string
  diskTotal: string
  battery: number
  charging: boolean
}>({
  cpu: 0,
  mem: 0,
  memUsed: '',
  memTotal: '',
  disk: 0,
  diskUsed: '',
  diskTotal: '',
  battery: 100,
  charging: false,
})

// Top processes pushed from Hammerspoon
export const topProcesses = writable<
  { name: string; cpu: number; mem: string }[]
>([])

// Now playing pushed from Hammerspoon
export const nowPlaying = writable<{
  track: string
  artist: string
  album: string
  artUrl: string
  playing: boolean
  position: number
  duration: number
} | null>(null)

// Clipboard history pushed from Hammerspoon
export const clipboardHistory = writable<
  { text: string; timestamp: number }[]
>([])

// Calendar events (fetched from JS or pushed from Lua)
export const calendarEvents = writable<
  { title: string; start: string; end: string; allDay: boolean; calendar: string }[]
>([])

// Downloads list pushed from Hammerspoon
export const recentDownloads = writable<
  { name: string; size: string; path: string }[]
>([])

// Screenshots pushed from Hammerspoon
export const recentScreenshots = writable<
  { name: string; path: string; thumbnail: string }[]
>([])

// Todoist tasks (fetched from JS)
export const todoistTasks = writable<
  { id: string; content: string; priority: number; due: string | null; completed: boolean }[]
>([])
