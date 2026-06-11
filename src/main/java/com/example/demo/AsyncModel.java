package com.example.demo;

import java.util.concurrent.Callable;

import org.springframework.ui.Model;

public interface AsyncModel extends Model {

    Model addAttribute(String attributeName, Callable<?> attributeValue);

}
