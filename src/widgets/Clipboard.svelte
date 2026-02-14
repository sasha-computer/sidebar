<script lang="ts">
  import { ClipboardList, Copy } from 'lucide-svelte'
  import { clipboardHistory } from '../lib/stores'
  import { sendToLua } from '../lib/bridge'

  function copyItem(text: string) {
    sendToLua('copyToClipboard', { text })
  }

  function truncate(text: string, max: number = 80): string {
    if (text.length <= max) return text
    return text.slice(0, max) + '...'
  }
</script>

<div class="space-y-3">
  <div class="flex items-center gap-2 text-muted">
    <ClipboardList size={13} />
    <span class="text-[10px] font-medium uppercase tracking-wider">Clipboard</span>
  </div>

  {#if $clipboardHistory.length > 0}
    <div class="space-y-1.5">
      {#each $clipboardHistory.slice(0, 5) as item}
        <button
          onclick={() => copyItem(item.text)}
          class="w-full text-left group flex items-start gap-1.5 cursor-pointer bg-transparent border-none p-0"
        >
          <Copy size={10} class="text-muted group-hover:text-accent transition-colors mt-0.5 shrink-0" />
          <span class="text-[10px] text-subtle group-hover:text-text transition-colors leading-tight break-all">
            {truncate(item.text)}
          </span>
        </button>
      {/each}
    </div>
  {:else}
    <div class="text-muted text-xs">No clipboard history</div>
  {/if}
</div>
