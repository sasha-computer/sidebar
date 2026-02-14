<script lang="ts">
  import { CalendarDays } from 'lucide-svelte'
  import { calendarEvents } from '../lib/stores'

  const now = new Date()
  const today = now.getDate()
  const month = now.toLocaleDateString('en-GB', { month: 'long', year: 'numeric' })
  const dayOfWeek = now.toLocaleDateString('en-GB', { weekday: 'long' })
  const dateStr = now.toLocaleDateString('en-GB', { day: 'numeric', month: 'long' })

  // Build mini calendar grid
  const year = now.getFullYear()
  const monthIdx = now.getMonth()
  const firstDay = new Date(year, monthIdx, 1).getDay()
  const daysInMonth = new Date(year, monthIdx + 1, 0).getDate()
  // Monday = 0, adjust from Sunday = 0
  const startOffset = firstDay === 0 ? 6 : firstDay - 1

  const days: (number | null)[] = []
  for (let i = 0; i < startOffset; i++) days.push(null)
  for (let i = 1; i <= daysInMonth; i++) days.push(i)

  const weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']

  function formatEventTime(dateStr: string): string {
    const d = new Date(dateStr)
    return d.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })
  }
</script>

<div class="space-y-3">
  <div class="flex items-center gap-2 text-muted">
    <CalendarDays size={13} />
    <span class="text-[10px] font-medium uppercase tracking-wider">Calendar</span>
  </div>

  <div class="flex items-baseline justify-between">
    <div>
      <div class="text-lg font-medium text-text">{dayOfWeek}</div>
      <div class="text-subtle text-xs">{dateStr}</div>
    </div>
  </div>

  <!-- Mini calendar -->
  <div class="grid grid-cols-7 gap-0.5 text-center text-[10px]">
    {#each weekdays as wd}
      <div class="text-muted py-0.5">{wd}</div>
    {/each}
    {#each days as day}
      {#if day === null}
        <div></div>
      {:else}
        <div
          class="py-0.5 rounded {day === today
            ? 'bg-accent text-base font-bold'
            : 'text-subtle'}"
        >
          {day}
        </div>
      {/if}
    {/each}
  </div>

  <!-- Events -->
  {#if $calendarEvents.length > 0}
    <div class="space-y-1.5 pt-1">
      {#each $calendarEvents.slice(0, 4) as event}
        <div class="flex gap-2 text-xs">
          <span class="text-accent shrink-0">
            {#if event.allDay}
              all day
            {:else}
              {formatEventTime(event.start)}
            {/if}
          </span>
          <span class="text-text truncate">{event.title}</span>
        </div>
      {/each}
    </div>
  {:else}
    <div class="text-muted text-xs">No events today</div>
  {/if}
</div>
