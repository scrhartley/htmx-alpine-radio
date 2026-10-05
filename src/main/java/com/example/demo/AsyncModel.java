package com.example.demo;

import java.util.Collection;
import java.util.Map;
import java.util.concurrent.Callable;

import org.springframework.ui.Model;

public interface AsyncModel extends Model {

    AsyncModel addAttribute(String attributeName, Callable<?> attributeValue);

    @Override
    AsyncModel addAttribute(String attributeName, Object attributeValue);
    @Override
    AsyncModel addAttribute(Object attributeValue);
    @Override
    AsyncModel addAllAttributes(Collection<?> attributeValues);
    @Override
    AsyncModel addAllAttributes(Map<String, ?> attributes);
    @Override
    AsyncModel mergeAttributes(Map<String, ?> attributes);

}
