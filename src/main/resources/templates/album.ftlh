<!DOCTYPE html>
<html lang="en">
    <#include "record_macros.ftlh">

    <#macro lazyTitle>${album.name} by ${album.artist}</#macro>
    <@Head title=lazyTitle>
        <script defer src="<@spring.url '/webjars/alpinejs/dist/cdn.min.js'/>"></script>
        <script>
            <#-- General Alpine + htmx fix that prevents the back button causing additional empty rows. -->
            document.addEventListener('htmx:beforeHistorySave', (evt) => {
                window.Alpine?.destroyTree(evt.detail.historyElt);
            });

            function setCurrentTrack(idx, playing) {
                let album = Alpine.store('album');
                Alpine.store('currentTrack', {
                    ...album.tracks[idx],
                    artist: album.artist, albumImage: album.imageUrl, albumId: album.id
                });
                Alpine.store('isPlaying', playing);
            }
        </script>
    </@Head>
    <@Body preferClientRender=true lazyPlayer=false contentAttrs={ "aria-labelledby": "page-heading" }>
        <script>
            (init => window.Alpine ? init() : document.addEventListener('alpine:init', init))(() => {
                Alpine.store('album', ${toJson(album)});
            });
        </script>
        <div class="container mx-auto max-w-screen-lg px-6 lg:px-0 flex flex-col items-start md:items-end md:flex-row pt-8 pb-12">
            <@Record />
            <div class="flex-1 flex flex-col justify-end pt-8">
                <h1 id="page-heading">
                    <div class="text-5xl font-bold tracking-tight text-gray-900">${album.name}</div>
                    <div class="mt-3 text-3xl">${album.artist}</div>
                </h1>
                <div class="mt-2 text-lg">${album.genre} — ${album.yearReleased}</div>
                <div class="mt-3 flex">
                     <button type="button" onclick="setCurrentTrack(0, true)"
                         class="text-pink-700 bg-gray-100 hover:bg-gray-200 focus:ring-4 focus:outline-none focus:ring-gray-100 font-medium rounded-lg text-lg px-10 py-3 text-center inline-flex items-center dark:focus:ring-gray-500 mr-4">
                         <svg aria-hidden="true" class="w-6 h-6 mr-2 -ml-1 text-pink-700" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z"></path></svg>Play</button>
                     <button disabled type="button" class="opacity-50 text-pink-600 bg-gray-100 font-medium rounded-lg text-lg px-10 py-3 text-center inline-flex items-center mr-4">
                         <svg aria-hidden="true" class="w-6 h-6 mr-2 -ml-1 text-pink-600" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z"></path></svg>Shuffle</button>
                </div>
            </div>
        </div>
        <div class="container mx-auto max-w-screen-lg mb-10">
            <@TrackList />
        </div>
    </@Body>

</html>


<#macro Record>
    <div class="relative shadow-xl mr-32 w-72 md:w-auto">
        <img
          src="${album.imageUrl}" alt="${album.name}" aria-hidden="true"
          width="400" height="400" class="block rounded-md tag-album-cover relative z-10 bg-white"
          style="view-transition-name: record-${album.id};" />
        <img x-data="{ isPlayingCurrentRecord: () => $store.isPlaying && $store.currentTrack?.albumId === '${album.id}' }"
          src="<@spring.url '/vinyl-lp-400.webp'/>" width="400" height="400" alt aria-hidden="true"
          class="absolute top-0 opacity-0 vinyl-image" <#rt>
          :class="isPlayingCurrentRecord() ? 'vinyl-animation-in-spinning' : 'vinyl-animation-in'"<#lt>
          style="view-transition-name: vinyl-${album.id};" />
    </div>
</#macro>

<#macro TrackList>
    <ul x-data class="text-xl" aria-label="Tracklist">
        <template x-for="(track, index) in $store.album.tracks">
            <li x-data="{ isCurrentTrack: () => $store.currentTrack?.id === track.id }" class="first-of-type:border-t border-b">
                <button type="button" :aria-current="isCurrentTrack()"
                        @click="setCurrentTrack(index, isCurrentTrack() ? !$store.isPlaying : true)"
                        class="hover:bg-gray-50 focus-visible:ring-2 focus:outline-none focus:ring-black cursor-pointer px-6 py-4 flex basis grow w-full items-center">
                    <template x-if="!isCurrentTrack()">
                        <span x-text="track.position" class="text-gray-500 w-8 mr-2"></span>
                    </template>
                    <template x-if="isCurrentTrack()">
                        <span class="text-gray-500 w-8 mr-2">
                            <template x-if="$store.isPlaying"><@PlayIcon /></template>
                            <template x-if="!$store.isPlaying"><@PauseIcon /></template>
                        </span>
                    </template>
                    <span x-text="track.title"  class="font-medium"></span>
                    <span x-text="track.length" class="text-gray-500 ml-auto"></span>
                </button>
            </li>
        </template>
    </ul>
</#macro>


<#macro PlayIcon>
  <svg xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 20 20" fill="currentColor" aria-hidden="true" focusable="false"
    class="w-6 h-6 mr-2 ml-1 text-pink-600">
    <path fill-rule="evenodd" clip-rule="evenodd"
      d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z"
    ></path>
  </svg>
</#macro>

<#macro PauseIcon>
  <svg xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" focusable="false"
    class="w-6 h-6 mr-2 ml-1 text-pink-600">
    <path fill-rule="evenodd" clip-rule="evenodd"
      d="M2.25 12c0-5.385 4.365-9.75 9.75-9.75s9.75 4.365 9.75 9.75-4.365 9.75-9.75 9.75S2.25 17.385 2.25 12zM9 8.25a.75.75 0 00-.75.75v6c0 .414.336.75.75.75h.75a.75.75 0 00.75-.75V9a.75.75 0 00-.75-.75H9zm5.25 0a.75.75 0 00-.75.75v6c0 .414.336.75.75.75H15a.75.75 0 00.75-.75V9a.75.75 0 00-.75-.75h-.75z"
    />
  </svg>
</#macro>