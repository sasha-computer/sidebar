<script lang="ts">
  import { Cpu, MemoryStick, HardDrive, Battery } from 'lucide-svelte'
  import { systemStats } from '../lib/stores'

  function barColor(pct: number): string {
    if (pct > 90) return 'bg-red'
    if (pct > 70) return 'bg-peach'
    if (pct > 50) return 'bg-yellow'
    return 'bg-green'
  }
</script>

<div class="space-y-3">
  <div class="flex items-center gap-2 text-muted">
    <Cpu size={13} />
    <span class="text-[10px] font-medium uppercase tracking-wider">System</span>
  </div>

  <div class="space-y-2">
    <!-- CPU -->
    <div class="space-y-0.5">
      <div class="flex justify-between text-[10px]">
        <span class="text-subtle">CPU</span>
        <span class="text-text">{$systemStats.cpu.toFixed(0)}%</span>
      </div>
      <div class="h-1 bg-overlay rounded-full overflow-hidden">
        <div class="h-full {barColor($systemStats.cpu)} rounded-full transition-all duration-500" style="width: {$systemStats.cpu}%"></div>
      </div>
    </div>

    <!-- Memory -->
    <div class="space-y-0.5">
      <div class="flex justify-between text-[10px]">
        <span class="text-subtle">MEM</span>
        <span class="text-text">{$systemStats.mem.toFixed(0)}%
          {#if $systemStats.memUsed}
            <span class="text-muted">{$systemStats.memUsed}/{$systemStats.memTotal}</span>
          {/if}
        </span>
      </div>
      <div class="h-1 bg-overlay rounded-full overflow-hidden">
        <div class="h-full {barColor($systemStats.mem)} rounded-full transition-all duration-500" style="width: {$systemStats.mem}%"></div>
      </div>
    </div>

    <!-- Disk -->
    <div class="space-y-0.5">
      <div class="flex justify-between text-[10px]">
        <span class="text-subtle">DSK</span>
        <span class="text-text">{$systemStats.disk.toFixed(0)}%
          {#if $systemStats.diskUsed}
            <span class="text-muted">{$systemStats.diskUsed}/{$systemStats.diskTotal}</span>
          {/if}
        </span>
      </div>
      <div class="h-1 bg-overlay rounded-full overflow-hidden">
        <div class="h-full {barColor($systemStats.disk)} rounded-full transition-all duration-500" style="width: {$systemStats.disk}%"></div>
      </div>
    </div>

    <!-- Battery -->
    <div class="space-y-0.5">
      <div class="flex justify-between text-[10px]">
        <span class="text-subtle">BAT</span>
        <span class="text-text">
          {$systemStats.battery}%
          {#if $systemStats.charging}
            <span class="text-green">⚡</span>
          {/if}
        </span>
      </div>
      <div class="h-1 bg-overlay rounded-full overflow-hidden">
        <div class="h-full {barColor(100 - $systemStats.battery)} rounded-full transition-all duration-500" style="width: {$systemStats.battery}%"></div>
      </div>
    </div>
  </div>
</div>
