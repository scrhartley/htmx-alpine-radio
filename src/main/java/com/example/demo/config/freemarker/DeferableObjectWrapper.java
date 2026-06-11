package com.example.demo.config.freemarker;

import java.io.IOException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

import freemarker.core.Environment;
import freemarker.template.DefaultObjectWrapper;
import freemarker.template.TemplateModel;
import freemarker.template.TemplateModelException;
import freemarker.template.Version;

public class DeferableObjectWrapper extends DefaultObjectWrapper {

    private final boolean autoFlush;

    public DeferableObjectWrapper(Version incompatibleImprovements) {
        this(incompatibleImprovements, true);
    }
    public DeferableObjectWrapper(Version incompatibleImprovements, boolean autoFlush) {
        super(incompatibleImprovements);
        this.autoFlush = autoFlush;
    }

    @Override
    protected TemplateModel handleUnknownType(Object obj) throws TemplateModelException {
        if (obj instanceof Future<?> future) {
            return handleFuture(future);
        }
        return super.handleUnknownType(obj);
    }

    private TemplateModel handleFuture(Future<?> future) throws TemplateModelException {
        // Send the already finished content to the browser (streaming or chunked transfer-encoding).
        // Note: doesn't do anything in an attempt block.
        if (autoFlush) {
            try {
                Environment env = Environment.getCurrentEnvironment();
                env.getOut().flush();
            } catch (IOException e) {
                throw new TemplateModelException("Failed flushing stream", e);
            }
        }
        try {
            return wrap(future.get()); // Blocking call
        } catch (ExecutionException e) {
            throw new TemplateModelException("Failure during Future's computation", e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new TemplateModelException("Interrupted waiting for Future", e);
        }
    }

}
