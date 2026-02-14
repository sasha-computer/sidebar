<script lang="ts">
  import { Activity } from 'lucide-svelte'
  import { topProcesses } from '../lib/stores'
</script>

<div class="space-y-3">
  <div class="flex items-center gap-2 text-muted">
    <Activity size={13} />
    <span class="text-[10px] font-medium uppercase tracking-wider">Top Processes</span>
  </div>

  {#if $topProcesses.length > 0}
    <div class="space-y-1">
      {#each $topProcesses.slice(0, 5) as proc}
        <div class="flex justify-between text-[10px]">
          <span class="text-text truncate max-w-[140px]">{proc.name}</span>
          <div class="flex gap-3 shrink-0">
            <span class="text-accent">{proc.cpu.toFixed(1)}%</span>
            <span class="text-muted w-12 text-right">{proc.mem}</span>
          </div>
        </div>
      {/each}
    </div>
  {:else}
    <div class="text-muted text-xs">Loading...</div>
  {/if}
</div>
