<script lang="ts">
  import { Camera } from 'lucide-svelte'
  import { recentScreenshots } from '../lib/stores'
  import { sendToLua } from '../lib/bridge'

  function openScreenshot(path: string) {
    sendToLua('openFile', { path })
  }
</script>

<div class="space-y-3">
  <div class="flex items-center gap-2 text-muted">
    <Camera size={13} />
    <span class="text-[10px] font-medium uppercase tracking-wider">Screenshots</span>
  </div>

  {#if $recentScreenshots.length > 0}
    <div class="grid grid-cols-3 gap-1.5">
      {#each $recentScreenshots.slice(0, 6) as screenshot}
        <button
          onclick={() => openScreenshot(screenshot.path)}
          class="aspect-video bg-overlay rounded overflow-hidden cursor-pointer border-none p-0 hover:ring-1 hover:ring-accent/50 transition-all"
        >
          {#if screenshot.thumbnail}
            <img
              src={screenshot.thumbnail}
              alt={screenshot.name}
              class="w-full h-full object-cover"
            />
          {:else}
            <div class="w-full h-full flex items-center justify-center">
              <Camera size={12} class="text-muted" />
            </div>
          {/if}
        </button>
      {/each}
    </div>
  {:else}
    <div class="text-muted text-xs">No recent screenshots</div>
  {/if}
</div>
