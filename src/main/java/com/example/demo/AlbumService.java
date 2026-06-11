package com.example.demo;

import java.util.List;

import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import com.example.demo.Album.Track;
import com.fasterxml.jackson.annotation.JsonCreator;

@Service
public class AlbumService {
    private final RestClient restClient;

    public AlbumService() {
        this.restClient = RestClient.create("https://music-api.charca.workers.dev");
    }

    @Cacheable("album")
    public Album getAlbum(int id) {
        JsonAlbum json = restClient
                .get().uri("/albums/{id}", id)
                .retrieve().body(JsonAlbum.class);
        return json.album();
    }

    @Cacheable("albums")
    public List<Album> getAlbums() {
        record Wrapper(List<JsonAlbum> results) {}
        List<JsonAlbum> json = restClient
                .get().uri("/albums")
                .retrieve().body(Wrapper.class).results();
        return json.stream().map(JsonAlbum::album).toList();
    }


    private record JsonAlbum(Album album) {
        @JsonCreator
        JsonAlbum(
                String idAlbum,
                String strAlbum,
                String strAlbumThumb,
                String strArtist,
                String strGenre,
                String intYearReleased,
                List<JsonTrack> tracks) {
            this(new Album(
                    idAlbum,
                    strAlbum,
                    fixImageURL(strAlbumThumb),
                    strArtist,
                    strGenre,
                    intYearReleased,
                    tracks.stream().map(JsonTrack::track).toList()
            ));
        }

        private static String fixImageURL(String url) {
            return url.replace("www.theaudiodb.com", "r2.theaudiodb.com");
        }
    }

    private record JsonTrack(Track track) {
        @JsonCreator
        JsonTrack(String id, int position, String title, String length) {
            this(new Track(id, position, title, length));
        }
    }

}
