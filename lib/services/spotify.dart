import 'dart:math';
import 'package:spotify/spotify.dart';

class SpotifyService extends SpotifyApi {
  static final credentials = SpotifyApiCredentials(
      '0b1ad9e7e5a343fd9616ab65465cf91e', '67db597e63594d9ea11ccfad94cd0c37');

  SpotifyService() : super(SpotifyService.credentials);

  final List<String> commonQualities = ['Low', 'Medium', 'High'];
  final List<String> specialQualities = ['Low', 'Medium', 'High', 'CDQ', 'HR'];

  Future<Album?> fetchRandomAlbum(List<String> userArtists) async {
    bool chooseFavorite = Random().nextDouble() < .10; // 10%
    Artist artist;

    if (chooseFavorite && userArtists.isNotEmpty) {
      final favoriteArtist = userArtists[Random().nextInt(userArtists.length)];
      artist = await search
          .get(favoriteArtist, types: [SearchType.artist])
          .first(1)
          .then((pages) => pages.first.items!.first);
    } else {
      String randomLetter = String.fromCharCode(Random().nextInt(26) + 97);

      final artists = await search
          .get(randomLetter, types: [SearchType.artist])
          .first(50)
          .then((pages) => pages.first.items!);
      artist = artists.elementAt(Random().nextInt(artists.length));
    }

    final albums = await artists.albums(artist.id!).all(50);
    final releases =
        albums.where((album) => album.albumType != AlbumType.compilation);
    return releases.elementAt(Random().nextInt(releases.length));
  }
}
