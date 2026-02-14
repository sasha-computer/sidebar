<script lang="ts">
  import { StickyNote } from 'lucide-svelte'
  import { sendToLua } from '../lib/bridge'

  let noteText = $state('')
  let saved = $state(false)

  function saveNote() {
    if (!noteText.trim()) return
    sendToLua('saveNote', { text: noteText.trim() })
    noteText = ''
    saved = true
    setTimeout(() => (saved = false), 2000)
  }

  function handleKeydown(e: KeyboardEvent) {
    if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
      e.preventDefault()
      saveNote()
    }
  }
</script>

<div class="space-y-3">
  <div class="flex items-center justify-between">
    <div class="flex items-center gap-2 text-muted">
      <StickyNote size={13} />
      <span class="text-[10px] font-medium uppercase tracking-wider">Quick Note</span>
    </div>
    {#if saved}
      <span class="text-green text-[10px]">Saved</span>
    {/if}
  </div>

  <div class="relative">
    <textarea
      bind:value={noteText}
      onkeydown={handleKeydown}
      placeholder="Jot something down..."
      rows={2}
      class="w-full bg-overlay text-text text-xs p-2 rounded border-none outline-none resize-none placeholder:text-muted focus:ring-1 focus:ring-accent/30"
    ></textarea>
    <div class="text-[9px] text-muted mt-1">⌘+Enter to save</div>
  </div>
</div>
