<div x-data="player" x-show="!!$store.currentTrack" x-cloak class="fixed bottom-0 left-0 right-0 bg-gray-100">
    <div class="flex-1 bg-gray-200 h-1.5 dark:bg-gray-700">
        <div class="bg-pink-700 h-1.5" :style="{ width: $data.progress + '%' }"></div>
    </div>
    <div class="container mx-auto max-w-screen-lg px-3 py-2 sm:px-6 sm:py-4 flex items-center gap-5">
        <img :src="$store.currentTrack?.albumImage" width="60" height="60" class="block rounded-md">
        <div class="flex-1 min-w-0">
            <p x-text="$store.currentTrack?.title" class="text-xl text-black font-medium overflow-hidden text-ellipsis whitespace-nowrap">title</p>
            <p x-text="$store.currentTrack?.artist" class="text-xl text-gray-700 overflow-hidden text-ellipsis whitespace-nowrap">artist</p>
        </div>
        <audio x-ref="media" src=""></audio>
        <div class="flex gap-6 items-center text-black">
            <button type="button" disabled class="opacity-50 focus-visible:ring-2 focus:outline-none focus:ring-black">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-10 h-10 hidden sm:block">
                    <path d="M9.195 18.44c1.25.713 2.805-.19 2.805-1.629v-2.34l6.945 3.968c1.25.714 2.805-.188 2.805-1.628V8.688c0-1.44-1.555-2.342-2.805-1.628L12 11.03v-2.34c0-1.44-1.555-2.343-2.805-1.629l-7.108 4.062c-1.26.72-1.26 2.536 0 3.256l7.108 4.061z"></path>
                </svg>
            </button>
            <button @click="$store.isPlaying = !$store.isPlaying" type="button">
                <template x-if="$store.isPlaying"><@PauseIcon /></template>
                <template x-if="!$store.isPlaying"><@PlayIcon /></template>
            </button>
            <button type="button" disabled class="opacity-50 focus-visible:ring-2 focus:outline-none focus:ring-black">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-10 h-10 hidden sm:block">
                    <path d="M5.055 7.06c-1.25-.714-2.805.189-2.805 1.628v8.123c0 1.44 1.555 2.342 2.805 1.628L12 14.471v2.34c0 1.44 1.555 2.342 2.805 1.628l7.108-4.061c1.26-.72 1.26-2.536 0-3.256L14.805 7.06C13.555 6.346 12 7.25 12 8.688v2.34L5.055 7.06z"></path>
                </svg>
            </button>
        </div>
    </div>
</div>
<#assign PLAYER_MAX_SONGS = 4 />
<#assign PLAYER_SONGS_SEQ = (1..PLAYER_MAX_SONGS)?map(num -> '/mp3/song${num?c}.mp3')?map(springUrl) />
<script>
    (init => window.Alpine ? init() : document.addEventListener('alpine:init', init))(() => {
        <#-- This app doesn't have real songs: it only has a few songs
             that we will play over and over as the user uses the app. -->
        const PLAYER_SONGS = ${toJson(PLAYER_SONGS_SEQ)};
        const MAX_FPS = 30; <#-- Save CPU and avoid problems on high refresh displays -->
        const TOLERANCE_MS = 0.1;
        const MIN_DELTA_MS = 1000 / MAX_FPS - TOLERANCE_MS;
        Alpine.data('player', () => ({
            progress: 0,

            init() {
                this.$watch('$store.currentTrack?.id', (newId, oldId) => newId !== oldId && this.updatePlayingSong());
                this.$watch('$store.isPlaying', (play) => this.updatePlaying(play));
            },
            updatePlayingSong() {
                const media = this.$refs.media;
                const newNumber = ((media._songNumber || 0) % ${PLAYER_SONGS_SEQ?size}) + 1;
                media._songNumber = newNumber;
                media.src = PLAYER_SONGS[newNumber - 1];
                media.currentTime = 0;
                media.play();
            },
            updatePlaying(play) {
                const media = this.$refs.media;
                if (play) {
                    media.play();
                    media._playingFrame = requestAnimationFrame(
                            this._whilePlaying.bind(this, media, document.timeline.currentTime));
                } else {
                    media.pause();
                    cancelAnimationFrame(media._playingFrame);
                }
            },
            _whilePlaying(media, then) {
                const duration = media.duration;
                const now = document.timeline.currentTime;
                const runNow = !!duration && (now - then >= MIN_DELTA_MS);
                if (runNow) {
                    const percentage = (media.currentTime * 100) / duration;
                    if (percentage < 99.99) {
                        this.progress = percentage;
                    } else {
                        this.progress = 0;
                        Alpine.store('isPlaying', false); // Triggers updatePlaying
                    }
                }
                media._playingFrame = requestAnimationFrame(
                        this._whilePlaying.bind(this, media, runNow ? now : then));
            }
        }));
    });
</script>

<#macro PlayIcon><@_PlayPauseIcon
    "M4.5 5.653c0-1.426 1.529-2.33 2.779-1.643l11.54 6.348c1.295.712 1.295 2.573 0 3.285L7.28 19.991c-1.25.687-2.779-.217-2.779-1.643V5.653z" /></#macro>
<#macro PauseIcon><@_PlayPauseIcon
    "M6.75 5.25a.75.75 0 01.75-.75H9a.75.75 0 01.75.75v13.5a.75.75 0 01-.75.75H7.5a.75.75 0 01-.75-.75V5.25zm7.5 0A.75.75 0 0115 4.5h1.5a.75.75 0 01.75.75v13.5a.75.75 0 01-.75.75H15a.75.75 0 01-.75-.75V5.25z" /></#macro>

<#macro _PlayPauseIcon svgPath>
  <svg xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" focusable="false"
    class="w-10 h-10 sm:w-14 sm:h-14">
    <path fill-rule="evenodd" clip-rule="evenodd" d="${svgPath}"></path>
  </svg>
</#macro>