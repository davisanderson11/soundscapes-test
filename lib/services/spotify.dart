import 'dart:math';
import 'package:spotify/spotify.dart';

class SpotifyService extends SpotifyApi {
  static final credentials = SpotifyApiCredentials(
      '0b1ad9e7e5a343fd9616ab65465cf91e', '67db597e63594d9ea11ccfad94cd0c37');

  SpotifyService() : super(SpotifyService.credentials);

  final List<String> commonQualities = ['Low', 'Medium', 'High'];
  final List<String> specialQualities = ['Low', 'Medium', 'High', 'CDQ', 'HR'];

  Future<Album?> fetchRandomArtistAndAlbum(List<String> userArtists) async {
    bool chooseFavorite = Random().nextDouble() < .10; // 10%
    String artistId;

    if (chooseFavorite && userArtists.isNotEmpty) {
      final favoriteArtist = userArtists[Random().nextInt(userArtists.length)];

      Artist artist = await search
          .get(favoriteArtist, types: [SearchType.artist])
          .first(1)
          .then((r) => r.first.items!.first);

      artistId = artist.id!;
    } else {
      String randomLetter = String.fromCharCode(Random().nextInt(26) + 97);
      final artists = await search
          .get(randomLetter, types: [SearchType.artist])
          .first(50)
          .then((pages) => pages.first.items!);
      Artist randomArtist = artists.elementAt(Random().nextInt(artists.length));
      artistId = randomArtist.id!;
    }

    return await _getRandomAlbumForArtist(artistId);
  }

  Future<Album?> _getRandomAlbumForArtist(String artistId) async {
    final albums =
        await artists.albums(artistId).all(50).then((iter) => iter.toList());
    return albums[Random().nextInt(albums.length)];
  }

  Future<TrackSimple> fetchRandomSongFromAlbum(String albumId) async {
    final tracks = await albums.tracks(albumId).all(50);
    return tracks.elementAt(Random().nextInt(tracks.length));
  }
}
