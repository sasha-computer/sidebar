<script lang="ts">
  import { CheckCircle, Circle, ListTodo, RefreshCw } from 'lucide-svelte'
  import { todoistTasks } from '../lib/stores'
  import { sendToLua } from '../lib/bridge'

  let loading = $state(false)
  let error = $state('')

  async function fetchTasks() {
    loading = true
    error = ''
    try {
      const token = (window as any).__TODOIST_TOKEN__
      if (!token) {
        // Token not injected yet, retry in 3s
        setTimeout(fetchTasks, 3000)
        return
      }
      const res = await fetch(
        'https://api.todoist.com/api/v1/tasks/filter?query=today',
        { headers: { Authorization: `Bearer ${token}` } }
      )
      if (!res.ok) throw new Error(`${res.status}`)
      const data = await res.json()
      const tasks = (data.results || []).map((t: any) => ({
        id: t.id,
        content: t.content,
        priority: t.priority,
        due: t.due?.date || null,
        completed: false,
      }))
      todoistTasks.set(tasks)
    } catch (e: any) {
      error = e.message
    } finally {
      loading = false
    }
  }

  async function completeTask(id: string) {
    try {
      const token = (window as any).__TODOIST_TOKEN__
      if (!token) return
      await fetch(`https://api.todoist.com/api/v1/tasks/${id}/close`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      })
      todoistTasks.update((tasks) => tasks.filter((t) => t.id !== id))
    } catch (e) {
      console.error('Failed to complete task:', e)
    }
  }

  function openTask(id: string) {
    sendToLua('openUrl', { url: `todoist://task?id=${id}` })
  }

  function priorityColor(p: number): string {
    if (p === 4) return 'text-red'
    if (p === 3) return 'text-peach'
    if (p === 2) return 'text-accent'
    return 'text-muted'
  }

  // Fetch on mount and every 2 minutes
  $effect(() => {
    fetchTasks()
    const interval = setInterval(fetchTasks, 120_000)
    return () => clearInterval(interval)
  })
</script>

<div class="space-y-3">
  <div class="flex items-center justify-between">
    <div class="flex items-center gap-2 text-muted">
      <ListTodo size={13} />
      <span class="text-[10px] font-medium uppercase tracking-wider">Todos</span>
    </div>
    <button
      onclick={fetchTasks}
      class="text-muted hover:text-accent transition-colors cursor-pointer bg-transparent border-none p-0"
    >
      <RefreshCw size={11} class={loading ? 'animate-spin' : ''} />
    </button>
  </div>

  {#if error}
    <div class="text-red text-xs">{error}</div>
  {/if}

  {#if $todoistTasks.length > 0}
    <div class="space-y-1">
      {#each $todoistTasks.slice(0, 6) as task}
        <div class="flex items-start gap-2 group">
          <button
            onclick={() => completeTask(task.id)}
            class="{priorityColor(task.priority)} hover:text-green transition-colors cursor-pointer bg-transparent border-none p-0 mt-0.5 shrink-0"
          >
            <Circle size={12} />
          </button>
          <button
            onclick={() => openTask(task.id)}
            class="text-text text-xs text-left truncate hover:text-accent transition-colors cursor-pointer bg-transparent border-none p-0"
          >
            {task.content}
          </button>
        </div>
      {/each}
    </div>
  {:else if !loading}
    <div class="text-muted text-xs">All done for today</div>
  {/if}
</div>
