package com.example.demo;

import java.util.List;

public record Album(
    String id,
    String name,
    String imageUrl,
    String artist,
    String genre,
    String yearReleased,
    List<Track> tracks) {

    public record Track(String id, int position, String title, String length) {}

}
