<script lang="ts">
  import { Music as MusicIcon, Play, Pause, SkipForward, SkipBack } from 'lucide-svelte'
  import { nowPlaying } from '../lib/stores'
  import { sendToLua } from '../lib/bridge'

  function togglePlay() {
    sendToLua('musicToggle')
  }

  function nextTrack() {
    sendToLua('musicNext')
  }

  function prevTrack() {
    sendToLua('musicPrev')
  }

  function formatTime(seconds: number): string {
    const m = Math.floor(seconds / 60)
    const s = Math.floor(seconds % 60)
    return `${m}:${s.toString().padStart(2, '0')}`
  }
</script>

<div class="space-y-3">
  <div class="flex items-center gap-2 text-muted">
    <MusicIcon size={13} />
    <span class="text-[10px] font-medium uppercase tracking-wider">Now Playing</span>
  </div>

  {#if $nowPlaying}
    <div class="flex gap-3 items-center">
      {#if $nowPlaying.artUrl}
        <img
          src={$nowPlaying.artUrl}
          alt="Album art"
          class="w-10 h-10 rounded shrink-0"
        />
      {:else}
        <div class="w-10 h-10 rounded bg-overlay shrink-0 flex items-center justify-center">
          <MusicIcon size={16} class="text-muted" />
        </div>
      {/if}
      <div class="min-w-0">
        <div class="text-xs text-text truncate font-medium">{$nowPlaying.track}</div>
        <div class="text-[10px] text-subtle truncate">{$nowPlaying.artist}</div>
      </div>
    </div>

    <!-- Progress bar -->
    {#if $nowPlaying.duration > 0}
      <div class="flex items-center gap-2 text-[9px] text-muted">
        <span>{formatTime($nowPlaying.position)}</span>
        <div class="flex-1 h-0.5 bg-overlay rounded-full overflow-hidden">
          <div
            class="h-full bg-accent rounded-full transition-all duration-1000"
            style="width: {($nowPlaying.position / $nowPlaying.duration) * 100}%"
          ></div>
        </div>
        <span>{formatTime($nowPlaying.duration)}</span>
      </div>
    {/if}

    <!-- Controls -->
    <div class="flex items-center justify-center gap-4">
      <button onclick={prevTrack} class="text-muted hover:text-text transition-colors cursor-pointer bg-transparent border-none p-0">
        <SkipBack size={13} />
      </button>
      <button onclick={togglePlay} class="text-text hover:text-accent transition-colors cursor-pointer bg-transparent border-none p-0">
        {#if $nowPlaying.playing}
          <Pause size={16} />
        {:else}
          <Play size={16} />
        {/if}
      </button>
      <button onclick={nextTrack} class="text-muted hover:text-text transition-colors cursor-pointer bg-transparent border-none p-0">
        <SkipForward size={13} />
      </button>
    </div>
  {:else}
    <div class="text-muted text-xs">Nothing playing</div>
  {/if}
</div>
