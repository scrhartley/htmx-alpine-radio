(function () {
    let internalApi
    let pageNonce

    // Anchors to script-src/default-src to avoid matching nonces in other CSP directives
    function extractNonceFromCSP(csp) {
        return csp?.match(/(?:script-src|default-src)[^;]*'nonce-([^']+)'/i)?.[1] ?? null
    }

    // Fallback: parse raw response HTML and extract nonce from meta CSP tag in <head>.
    // Only used for full-page responses with no CSP header.
    function extractNonceFromMetaTag(text) {
        let cspMeta = text.match(/<meta\s+[^>]*http-equiv\s*=\s*["']?Content-Security-Policy["']?[^>]*>/i)?.[0]
        let content = cspMeta?.match(/content\s*=\s*"([^"]*)"/i)?.[1]
        return extractNonceFromCSP(content)
    }

    function rewriteNonces(text, responseNonce, replacement) {
        let escaped = responseNonce.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
        return text.replace(
            new RegExp(`(nonce=)(["']?)${escaped}\\2`, 'gi'),
            (_, attr, quote) => replacement ? `${attr}${quote}${replacement}${quote}` : ''
        )
    }

    function isSameOrigin(ctx) {
        let responseURL = ctx?.response?.raw?.url
        if (!responseURL) return false
        try { if (new URL(responseURL).origin !== location.origin) return false }
        catch (_) { return false }
        return true
    }

    // Rewrites response nonces to pageNonce in raw HTML before fragment parsing.
    // Always scrubs stolen pageNonce. Only promotes response nonce for verified same-origin.
    function processHead(text, pageNonce, ctx) {
        // Always scrub stolen pageNonce from any response. The server cannot know the
        // page nonce, so its presence indicates a stolen-nonce injection attempt.
        text = rewriteNonces(text, pageNonce, '')

        if (isSameOrigin(ctx)) { // Only promote response nonce for verified same-origin responses
            let responseNonce = extractNonceFromCSP(ctx?.response?.headers?.get('Content-Security-Policy'))
                            ?? extractNonceFromMetaTag(text)
            if (responseNonce && responseNonce !== pageNonce) {
                text = rewriteNonces(text, responseNonce, pageNonce)
            }
        }

        return text
    }

    function preventEditMetaCsp(elt, detail) {
        let el = detail.headElement
        if (el.tagName === 'META' && el.getAttribute('http-equiv')?.toLowerCase() === 'content-security-policy') {
            detail.cancelled = true
        }
    }

    htmx.registerExtension("head-csp", {
        init: (api) => {
            internalApi = api
            pageNonce = document.querySelector('script[nonce]')?.nonce
        },
        htmx_head_before_merge: (elt, detail) => {
            if (!pageNonce) return;
            let ctx = detail.ctx

            let realText = ctx.response.raw.text.bind(ctx.response.raw)
            ctx.response.raw.text = async () => {
                let text = await realText()

                let match = text.match(/<head[\s>].*<\/head>/isd)
                if (match) {
                    let head = match[0], indices = match.indices[0]
                    head = processHead(head, pageNonce, ctx)
                    text = text.slice(0, indices[0]) + head + text.slice(indices[1])
                }

                return text
            }
        },
        htmx_head_before_add: preventEditMetaCsp,
        htmx_head_before_remove: preventEditMetaCsp
    })
})()