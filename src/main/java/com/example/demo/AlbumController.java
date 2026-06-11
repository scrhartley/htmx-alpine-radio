package com.example.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@Controller
public class AlbumController {

    @Autowired
    AlbumService albumService;

    @GetMapping("/")
    public String records(AsyncModel model) {
        model.addAttribute("albums", albumService::getAlbums);
        return "records";
    }

    @GetMapping("/album/{id}")
    public String albumById(@PathVariable int id, AsyncModel model) {
        model.addAttribute("album", () -> {
            Thread.sleep(50); // Help comparison with Astro version.
            return albumService.getAlbum(id);
        });
        return "album";
    }

    @GetMapping("/player")
    public String player() {
        return "player";
    }

}
