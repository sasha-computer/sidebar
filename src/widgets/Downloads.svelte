<script lang="ts">
  import { Download, FolderOpen } from 'lucide-svelte'
  import { recentDownloads } from '../lib/stores'
  import { sendToLua } from '../lib/bridge'

  function revealInFinder(path: string) {
    sendToLua('revealFile', { path })
  }

  function openDownloads() {
    sendToLua('openFolder', { path: '~/Downloads' })
  }
</script>

<div class="space-y-3">
  <div class="flex items-center justify-between">
    <div class="flex items-center gap-2 text-muted">
      <Download size={13} />
      <span class="text-[10px] font-medium uppercase tracking-wider">Downloads</span>
    </div>
    <button
      onclick={openDownloads}
      class="text-muted hover:text-accent transition-colors cursor-pointer bg-transparent border-none p-0"
    >
      <FolderOpen size={11} />
    </button>
  </div>

  {#if $recentDownloads.length > 0}
    <div class="space-y-1">
      {#each $recentDownloads.slice(0, 4) as file}
        <button
          onclick={() => revealInFinder(file.path)}
          class="w-full flex justify-between items-center group cursor-pointer bg-transparent border-none p-0"
        >
          <span class="text-[10px] text-text group-hover:text-accent transition-colors truncate max-w-[180px] text-left">
            {file.name}
          </span>
          <span class="text-[9px] text-muted shrink-0">{file.size}</span>
        </button>
      {/each}
    </div>
  {:else}
    <div class="text-muted text-xs">No recent downloads</div>
  {/if}
</div>
