<!DOCTYPE html>
<html lang="en">
    <#include "record_macros.ftlh">

    <@Head />
    <@Body contentClass="py-8">
        <div class="container mx-auto max-w-screen-lg px-6 lg:px-0 flex items-center flex-wrap pt-4 pb-12">
            <h2 class="font-bold text-3xl text-black tracking-tight mb-12">
                Recently Played
            </h2>
            <div class="w-full grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-6">
                <#list albums as album>
                    <div class="flex flex-col">
                        <a href="/album/${album.id}" class="text-black hover:text-pink-500">
                            <div class="shadow-md hover:shadow-lg relative fades-in"
                                 style="view-transition-name: record-${album.id};">
                                <img <#rt>
                                  width="400" height="400" class="card-image rounded-md relative z-10"<#lt>
                                  src="${album.imageUrl}"
                                  alt="${album.name}" <#rt>
                                /><#lt>
                                <img src="<@spring.url '/vinyl-lp-400.webp'/>" width="400" height="400" alt aria-hidden="true"
                                     class="absolute top-0 opacity-0 vinyl-image" <#rt>
                                     style="view-transition-name: vinyl-${album.id};"><#lt>
                            </div>
                            <p class="pt-4 font-semibold">${album.name}</p>
                            <p class="pt-1 text-gray-700">${album.artist}</p>
                        </a>
                    </div>
                </#list>
            </div>
        </div>
   </@Body>

</html>