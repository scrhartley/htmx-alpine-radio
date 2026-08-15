package com.example.demo.config;

import static com.fasterxml.jackson.databind.SerializationFeature.*;

import java.io.IOException;
import java.io.StringWriter;
import java.util.List;
import java.util.Map;

import org.springframework.boot.autoconfigure.freemarker.FreeMarkerVariablesCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.support.RequestContext;
import org.springframework.web.servlet.view.freemarker.FreeMarkerView;

import com.example.demo.config.freemarker.ExceptionAwareWriter;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import freemarker.core.Environment;
import freemarker.core.MarkupOutputFormat;
import freemarker.core.OutputFormat;
import freemarker.ext.jakarta.servlet.FreemarkerServlet;
import freemarker.ext.jakarta.servlet.HttpRequestHashModel;
import freemarker.ext.util.WrapperTemplateModel;
import freemarker.template.SimpleScalar;
import freemarker.template.TemplateBooleanModel;
import freemarker.template.TemplateDirectiveBody;
import freemarker.template.TemplateDirectiveModel;
import freemarker.template.TemplateException;
import freemarker.template.TemplateMethodModelEx;
import freemarker.template.TemplateModel;
import freemarker.template.TemplateModelException;
import freemarker.template.TemplateScalarModel;
import freemarker.template.utility.DeepUnwrap;
import jakarta.servlet.http.HttpServletRequest;

@Configuration
public class FreemarkerConfig {

    @Bean
    public FreeMarkerVariablesCustomizer additionalFreeMarkerVariables(ObjectMapper objectMapper) {
        return (Map<String, Object> variables) -> {
            var mapper = objectMapper.copy().disable(INDENT_OUTPUT);
            variables.put("toJson", new ToJsonMethodModel(mapper));
            variables.put("springUrl", new SpringUrlMethodModel());
            variables.put("local", ExceptionAwareAssign.localAssignment()); // Co-exists with the built-in directive.
            variables.put("isMobile", new MobileBrowserCheckMethodModel());
        };
    }


    record ToJsonMethodModel(ObjectMapper mapper) implements TemplateMethodModelEx {
        @Override
        public TemplateModel exec(List args) throws TemplateModelException {
            if (args.size() != 1) {
                throw new TemplateModelException(
                        "This directive expects exactly 1 argument and found " + args.size() + ".");
            }
            try {
                Object object = DeepUnwrap.unwrap((TemplateModel) args.get(0));
                String json = mapper.writeValueAsString(object);
                return asModel(json);
            } catch (JsonProcessingException e) {
                throw new TemplateModelException(e);
            }
        }

        private static TemplateModel asModel(String json) throws TemplateModelException {
            Environment env = Environment.getCurrentEnvironment();
            OutputFormat format = env.getCurrentTemplate().getOutputFormat();
            if (format instanceof MarkupOutputFormat<?> mof) {
                // Return as markup output because we don't want escaping.
                return mof.fromMarkup(json);
            } else {
                return new SimpleScalar(json);
            }
        }
    }

    /*
        An alternative to:
        <#import "/spring.ftl" as spring />
        <script defer src="<@spring.url '/path/to/my.js'/>"></script>
        or
        <#import "/spring.ftl" as spring />
        <#function url param>
            <#local result><@spring.url param /></#local>
            <#return result>
        </#function>
        <script defer src="${url('/path/to/my.js')}"></script>
     */
    static class SpringUrlMethodModel implements TemplateMethodModelEx {
        @Override
        public String exec(List args) throws TemplateModelException {
            if (args.size() != 1) {
                throw new TemplateModelException(
                        "This directive expects exactly 1 argument and found " + args.size() + ".");
            }
            Object arg = args.get(0);
            if (!(arg instanceof TemplateScalarModel scalar)) {
                throw new TemplateModelException(
                        "Unexpected type for param: " + arg.getClass().getSimpleName());
            }
            String url = scalar.getAsString();
            return context().getContextUrl(url);
        }

        private static RequestContext context() throws TemplateModelException {
            Environment env = Environment.getCurrentEnvironment();
            TemplateModel model = env.getVariable(FreeMarkerView.SPRING_MACRO_REQUEST_CONTEXT_ATTRIBUTE);
            return (RequestContext) ((WrapperTemplateModel) model).getWrappedObject();
        }
    }

    // Unlike the built-in directives #assign, #local and #global, this uses ExceptionAwareWriter
    // and so the handlers in HtmlStreamTemplateExceptionHandlers will work as expected.
    static class ExceptionAwareAssign implements TemplateDirectiveModel {
        private static final String VAR_PARAM = "var";
        private enum Scope { NORMAL, LOCAL, GLOBAL }
        private final Scope scope;

        private ExceptionAwareAssign(Scope scope) {
            this.scope = scope;
        }

        public static ExceptionAwareAssign normalAssignment() {
            return new ExceptionAwareAssign(Scope.NORMAL);
        }

        public static ExceptionAwareAssign localAssignment() {
            return new ExceptionAwareAssign(Scope.LOCAL);
        }

        public static ExceptionAwareAssign globalAssignment() {
            return new ExceptionAwareAssign(Scope.GLOBAL);
        }

        @Override
        public void execute(Environment env, Map params, TemplateModel[] loopVars, TemplateDirectiveBody body)
                throws TemplateException, IOException {
            if (loopVars.length != 0) {
                throw new TemplateModelException("This directive doesn't allow loop variables.");
            }
            if (body == null) {
                throw new TemplateModelException("missing body");
            }
            if (params.size() > 1) {
                throw new TemplateModelException("This directive only supports a single parameter.");
            } else if (params.isEmpty()) {
                throw new TemplateModelException("This directive expects a parameter 'var' and found none.");
            }

            Map.Entry<?,?> entry = ((Map<?,?>) params).entrySet().iterator().next();
            if (!VAR_PARAM.equals(entry.getKey())) {
                throw new TemplateModelException("Expected param " + VAR_PARAM + ", found: " + entry.getKey());
            }
            Object varName = entry.getValue();
            if (!(varName instanceof TemplateScalarModel scalar)) {
                throw new TemplateModelException(VAR_PARAM + " doesn't evaluate to a string");
            }

            StringWriter writer = new StringWriter();
            body.render(new ExceptionAwareWriter(writer, env.getOut()));
            TemplateModel value = capturedStringToModel(writer.toString(), env);
            switch (scope) {
                case NORMAL -> env.setVariable(scalar.getAsString(), value);
                case LOCAL  -> env.setLocalVariable(scalar.getAsString(), value);
                case GLOBAL -> env.setGlobalVariable(scalar.getAsString(), value);
            }
        }

        private TemplateModel capturedStringToModel(String s, Environment env) throws TemplateModelException {
            OutputFormat outputFormat = env.getCurrentDirectiveCallPlace().getTemplate().getOutputFormat();
            return (outputFormat instanceof MarkupOutputFormat<?> mof)
                    ? mof.fromMarkup(s) : new SimpleScalar(s);
        }
    }


    static class MobileBrowserCheckMethodModel implements TemplateMethodModelEx {
        @Override
        public TemplateModel exec(List arguments) throws TemplateModelException {
            if (!arguments.isEmpty()) {
                throw new TemplateModelException("Arguments not allowed");
            }

            String userAgent = request().getHeader("User-Agent");
            boolean mobile = userAgent != null && userAgent.contains("Mobile");
            return mobile ? TemplateBooleanModel.TRUE : TemplateBooleanModel.FALSE;
        }

        private static HttpServletRequest request() throws TemplateModelException {
            Environment env = Environment.getCurrentEnvironment();
            TemplateModel model = env.getDataModelOrSharedVariable(FreemarkerServlet.KEY_REQUEST);
            return ((HttpRequestHashModel) model).getRequest();
        }
    }

}
