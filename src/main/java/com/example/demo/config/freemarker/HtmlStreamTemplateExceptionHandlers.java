package com.example.demo.config.freemarker;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.Writer;

import freemarker.core.Environment;
import freemarker.template.TemplateException;
import freemarker.template.TemplateExceptionHandler;

/**
 * With normal MVC, all the data is prepared beforehand and if there's an error,
 * then the web framework can then show some error content using a completely different view.
 * With a deferred approach, we've potentially already sent some content and the web framework
 * isn't helping us anymore. Implement error handling ourselves with some HTML or JS tricks.
 */
public interface HtmlStreamTemplateExceptionHandlers {

    // For production use
    // Note: Error path should prevent caching to avoid being cached as the content of the requested page.
    class MetaRefreshRethrowHandler implements TemplateExceptionHandler {
        private final String errorPath;
        private final String elementId;

        public MetaRefreshRethrowHandler(String errorPath) {
            this(errorPath, null);
        }
        public MetaRefreshRethrowHandler(String errorPath, String elementId) {
            this.errorPath = errorPath;
            this.elementId = elementId;
        }

        @Override
        public void handleTemplateException(
                TemplateException te, Environment env, Writer out) throws TemplateException {
            if (out instanceof ExceptionAwareWriter eaw) {
                out = eaw.getExceptionWriter();
            }

            if (!env.isInAttemptBlock()) {
                PrintWriter pw = (out instanceof PrintWriter outPw) ? outPw : new PrintWriter(out);
                StringBuilder builder = new StringBuilder();
                // For htmx: added dummy html to convince the DOMParser that we're in the body,
                // because otherwise it will notice that the first tag is a head element.
                builder.append("<pre></pre>").append("<meta");
                if (elementId != null) {
                    builder.append(" id=\"").append(elementId).append('"');
                }
                builder.append(" http-equiv=\"refresh\" content=\"0; url=").append(errorPath).append("\">");
                pw.write(builder.toString());
                // Close the stream so that browser thinks it should act upon the redirect,
                // rather than just log the incomplete stream error in the console.
                pw.close();
            }
            TemplateExceptionHandler.RETHROW_HANDLER.handleTemplateException(te, env, out);
        }
    }


    // For development use
    class JsEnhancedHtmlDebugHandler implements TemplateExceptionHandler {
        private final static TemplateExceptionHandler BASE_HANDLER = TemplateExceptionHandler.HTML_DEBUG_HANDLER;
        private final String elementId;

        public JsEnhancedHtmlDebugHandler() {
            this(null);
        }
        public JsEnhancedHtmlDebugHandler(String elementId) {
            this.elementId = elementId;
        }

        @Override
        public void handleTemplateException(
                TemplateException te, Environment env, Writer out) throws TemplateException {
            if (out instanceof ExceptionAwareWriter eaw) {
                out = eaw.getExceptionWriter();
            }

            if (!env.isInAttemptBlock()) {
                // Pass TemplateExceptionHandler a different writer so that we don't care if it closes it or not,
                // and we can still write some JavaScript ourselves afterwards.
                // Unfortunately, document.body.innerHTML='' before the TemplateExceptionHandler doesn't work.
                StringWriter outCapture = new StringWriter();
                try {
                    BASE_HANDLER.handleTemplateException(te, env, outCapture);
                } catch (TemplateException baseTemplateException) { // Always thrown
                    throw te;
                } finally {
                    PrintWriter pw = (out instanceof PrintWriter outPw) ? outPw : new PrintWriter(out);
                    String html = outCapture.toString();
                    if (elementId != null) {
                        html = html.replaceFirst("<div ", "<div id=\"" + elementId + "\" ");
                    }
                    pw.write(html);
                    // Clear page so there's only the error message.
                    pw.write(
                            "<script>(self => setTimeout(() =>\n" +
                                "document.body.innerHTML = self.previousElementSibling.outerHTML\n" +
                            "))(document.currentScript);</script>");
                    //  Close the stream so that browser thinks it should render the debug HTML,
                    //  rather than just log the incomplete stream error in the console.
                    pw.close();
                }
            }
            else {
                BASE_HANDLER.handleTemplateException(te, env, out);
            }
            throw te; // Should never be reached
        }
    };

}
