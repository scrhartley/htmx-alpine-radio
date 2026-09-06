<#import "/spring.ftl" as spring />

<#macro Head title="">
    <head hx-head="append">
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width">
        <link rel="shortcut icon" href="<@spring.url '/icon-48x48.png'/>">
        <#-- -->
        <style>.flex { display: none; }</style><#-- Critical styles to avoid FOUC -->
        <@asyncStylesheet href=springUrl('/main.output.css') />
        <#-- -->
        <script defer src="<@spring.url '/webjars/htmx.org/dist/htmx.min.js'/>"></script>
        <script defer src="<@spring.url '/webjars/htmx-ext-head-support/dist/head-support.min.js'/>"></script>
        <#-- -->
        <#if title?is_macro>
            <#flush><#nested>
            <#flush><@_Title_ title=title />
        <#else>
            <@_Title_ title=title />
            <#flush><#nested>
        </#if>
    </head>
</#macro>

<#macro _Title_ title>
    <#if title?is_macro><@local var='title'><@title /></@local></#if>
    <title><#if title?has_content>${title} - </#if>htmx Alpine Records</title>
</#macro>

<#macro Body preferClientRender=false lazyPlayer=true contentClass="" contentAttrs={}>
    <body hx-ext="head-support" hx-boost="true" hx-target="#main" hx-select="#main"
          hx-swap="outerHTML transition:true show:window:top"
          id="html_error_fallback" hx-select-oob="#html_error_fallback"
          class="bg-white text-gray-600 work-sans leading-normal text-base tracking-normal">
        <div class="flex flex-col h-screen">
            <@_Header_ />
            <div id="main" hx-history-elt class="flex-1 overflow-auto">
                <section<#rt>
                        <#if contentClass?has_content> class="${contentClass}"</#if><#t>
                        <#list contentAttrs as attrName, attrVal> ${attrName}="${attrVal}"</#list>><#lt>
                    <#nested>
                </section>
                <@_Footer_ preferClientRender />
            </div>
            <#if lazyPlayer>
                <#-- Lazy load player (be ready for when we reach a page that can trigger showing it). -->
                <#-- Sets settle to 0 to avoid Alpine issue. -->
                <div hx-get="/player" hx-trigger="load[!!window.Alpine], alpine:init from:document"
                     hx-swap="outerHTML transition:false settle:0" hx-target="this" hx-select="unset"></div>
            <#else>
                <#include "player.ftlh">
            </#if>
        </div>
     </body>
</#macro>

<#macro _Header_>
    <nav class="w-full border-b bg-white" id="page-header">
        <div class="w-full container mx-auto max-w-screen-lg px-6 lg:px-0 flex flex-wrap items-center mt-0 py-6">
            <div>
                <a href="/" class="flex items-center tracking-tight no-underline hover:no-underline font-bold text-black text-xl"><#rt>
                    <svg class="w-8 h-8 mr-2" aria-hidden="true" focusable="false" data-icon="spring-initializr" role="img" <#t>
                         xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" viewBox="0 0 157.6 141.6"><#lt>
                    <g><path class="st0 fill-lime-600" d="M153.4,62.6l-30.2-52.3c-2.6-4.5-9.1-8.3-14.3-8.3H48.5c-5.2,0-11.7,3.7-14.3,8.3L4,62.6 c-2.6,4.5-2.6,12,0,16.5l30.2,52.3c2.6,4.5,9.1,8.3,14.3,8.3h60.4c5.2,0,11.7-3.7,14.3-8.3l30.2-52.3 C156.1,74.5,156.1,67.1,153.4,62.6z"></path>
                    <g><circle class="st1 fill-white" cx="36.7" cy="115.2" r="6.1"></circle></g>
                    <g><path class="st1 fill-white" d="M139,97.4C121.3,121,83.5,113,59.3,114.2c0,0-4.3,0.2-8.6,0.9c0,0,1.6-0.7,3.7-1.4c17-5.9,25-7.1,35.4-12.4 c19.4-9.9,38.7-31.6,42.7-54.1c-7.4,21.6-29.9,40.3-50.3,47.8c-14,5.2-39.3,10.2-39.3,10.2l-1-0.5C24.5,96.4,24,59,55.3,47 C69,41.7,82.2,44.6,97,41.1c15.8-3.8,34.1-15.6,41.6-31.1C146.9,34.8,156.9,73.5,139,97.4z"></path>
                    <path class="st0 fill-lime-600" d="M138.6,10c8.3,24.8,18.4,63.5,0.4,87.4c-11.1,14.8-30.1,17.2-48.7,17.2c-8.8,0-17.5-0.5-25.2-0.5 c-2,0-3.9,0-5.7,0.1c0,0-4.3,0.2-8.6,0.9c0,0,1.6-0.7,3.7-1.4c17-5.9,25-7.1,35.4-12.4c19.4-9.9,38.7-31.6,42.7-54.1 c-7.4,21.6-29.9,40.3-50.3,47.8c-14,5.2-39.3,10.2-39.3,10.2l0,0l-1-0.5C24.5,96.4,24,59,55.3,47C69,41.7,82.2,44.6,97,41.1 C112.8,37.4,131.1,25.5,138.6,10 M139.1,2.1l-3.2,6.6c-7.5,15.6-25.8,26.2-39.6,29.5C90.1,39.7,84,40,78.2,40.3 c-7.7,0.4-15.7,0.8-23.9,3.9C35,51.6,27.6,67.8,27.1,80.5c-0.5,12.1,4.7,22.6,13.2,26.9c0.5,0.3,1.6,0.9,2.5,0.9h1.3l0.2-0.2 c5.8-1.2,26.5-5.6,38.9-10.1c8.6-3.2,18.3-8.6,27.1-15.8c-6.5,6.9-14.1,12.7-21.8,16.6c-6.3,3.2-11.7,4.9-19.2,7.2 c-4.4,1.3-9.5,2.9-15.7,5c-2.2,0.7-3.8,1.5-3.9,1.5l-2.2,4.5l3.9,1.2c4.1-0.7,8.2-0.9,8.3-0.9c1.7-0.1,3.5-0.1,5.5-0.1 c3.7,0,7.6,0.1,11.7,0.3c4.4,0.1,8.9,0.3,13.5,0.3c18.5,0,39-2.2,51.1-18.4c14.1-18.8,14.2-48.3,0.1-90.2L139.1,2.1L139.1,2.1z"></path></g></g>
                    </svg><#rt>
                    Music Library<#t>
                </a><#lt>
            </div>
        </div>
    </nav>
</#macro>

<#macro _Footer_ clientRender>
    <footer <#rt>
        <#-- When something major on the page is using Alpine, we can get a better CLS score
             by rendering this at the same time (by also using Alpine).
             Seemingly not required in more recent versions of Chrome. -->
        <#if clientRender>x-data x-cloak </#if><#t>
        class="container mx-auto max-w-screen-lg px-6 lg:px-0 flex items-center flex-wrap pt-4 pb-32"><#lt>
        <div class="container flex px-3 py-8">
            <div class="w-full mx-auto flex flex-wrap">
                <div class="flex w-full lg:w-1/2">
                    <div class="px-3 md:px-0">
                        <h3 class="font-bold text-gray-900">About</h3>
                        <p class="py-4">
                            This is an <a class="underline decoration-dotted decoration-1 underline-offset-2" href="https://htmx.org" rel="noopener noreferrer">htmx</a>
                            and <a class="underline decoration-dotted decoration-1 underline-offset-2" href="https://alpinejs.dev" rel="noopener noreferrer">Alpine.js</a>
                            demo with support for the View Transitions API✨
                        </p>
                        <p>
                            For the original implementation, visit
                            <a href="https://astro-records.pages.dev/" rel="noopener noreferrer"
                               class="underline decoration-dotted decoration-1 underline-offset-2">Astro Records</a> 💿
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </footer>
</#macro>

<#macro asyncStylesheet href>
    <#--
        Pattern from: https://github.com/filamentgroup/loadCSS/blob/master/README.md
        Successor to pattern using rel="preload" in: https://web.dev/articles/defer-non-critical-css

        "no longer support or include a polyfill for a rel=preload markup pattern. This is because we have
        since determined that ... is simpler and better for performance, while the former preload pattern could
        sometimes conflict with resource priorities in ways that aren't helpful for loading CSS in a non-blocking way"
    -->
    <link rel="stylesheet" href="${href}" media="print" />
    <#-- Use a separate script tag, instead of a self-modifying onload attribute,
         in order to prevent the htmx head-support extension getting confused -->
    <script><#rt>
        let link = document.currentScript.previousElementSibling;<#t>
        link.addEventListener('load', () => { link.media='all'; }, {once: true});<#t>
    </script><#lt>
</#macro>
</#macro>