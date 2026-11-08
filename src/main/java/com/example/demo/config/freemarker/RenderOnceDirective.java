package com.example.demo.config.freemarker;

import static freemarker.core.CustomAttribute.*;

import java.io.IOException;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import freemarker.core.CallPlaceCustomDataInitializationException;
import freemarker.core.CustomAttribute;
import freemarker.core.Environment;
import freemarker.template.TemplateBooleanModel;
import freemarker.template.TemplateDirectiveBody;
import freemarker.template.TemplateDirectiveModel;
import freemarker.template.TemplateException;
import freemarker.template.TemplateModel;
import freemarker.template.TemplateModelException;
import freemarker.template.TemplateScalarModel;

// Inspiration: https://templ.guide/syntax-and-usage/render-once/
//
//    <#macro require_jQuery>
//        <@render_once>
//            <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script><#t>
//        </@render_once>
//    </#macro>
//    <@require_jQuery />  <#-- Renders something -->
//    <@require_jQuery />  <#-- Nothing to render -->
//
// If you #include a use of this directive multiple times then each will reset whether it has rendered.
// To avoid this you can use an optional string key:
//    <@render_once key="jQuery_key">
//        ...
//    </@render_once>
public class RenderOnceDirective implements TemplateDirectiveModel {

    private static final String PARAM_NAME = "key";

    private static final CustomAttribute STATE = new CustomAttribute(SCOPE_ENVIRONMENT) {
        @Override
        protected Set<?> create() {
            return new HashSet<>();
        }
    };

    @Override
    public void execute(Environment env, Map params, TemplateModel[] loopVars, TemplateDirectiveBody body)
            throws TemplateException, IOException {
        if (loopVars.length != 0) {
            throw new TemplateModelException("This directive doesn't support loop variables.");
        } else if (body == null) {
            throw new TemplateModelException("missing body");
        }

        Object key = getKey(params, env);
        @SuppressWarnings("unchecked")
        Set<Object> alreadyRun = (Set<Object>) STATE.get(env);

        boolean firstTime = alreadyRun.add(key);
        if (firstTime) {
            body.render(env.getOut());
        }
    }

    private static Object getKey(Map<?,?> params, Environment env) throws TemplateException {
        if (params.isEmpty()) {
            return getKeyForCallPlace(env);
        }

        final Object param;
        if (params.size() > 1) {
            throw new TemplateModelException(
                    "Too many arguments: expected 0 or 1 and found " + params.size());
        } else {
            Map.Entry<?,?> entry = params.entrySet().iterator().next();
            if (!PARAM_NAME.equals(entry.getKey())) {
                throw new TemplateModelException(
                        "Expected parameter '" + PARAM_NAME + "' and found: '" + entry.getKey() + "'");
            }
            param = entry.getValue();
        }
        if (!(param instanceof TemplateScalarModel)) {
            throw new TemplateModelException("Argument must be a string");
        }
        return ((TemplateScalarModel) param).getAsString();
    }

    // Returns Objects as keys since their identity based equals method gives the required level of uniqueness.
    //
    // Environment.getCurrentDirectiveCallPlace doesn't give a guarantee to always return
    // the same object unique per call-place nor any particular guarantee about their equality,
    // but its getOrCreateCustomData method guarantees that it won't recreate
    // the data as long as something else does not have access to a call place's data
    // (i.e. access via the directive's variable being hidden/replaced by something else).
    private static Object getKeyForCallPlace(Environment env) throws TemplateException {
        try {
            return env.getCurrentDirectiveCallPlace()
                    .getOrCreateCustomData(RenderOnceDirective.class, Object::new);
        }
        catch (CallPlaceCustomDataInitializationException e) {
            throw new TemplateException(e, env);
        }
    }

}
