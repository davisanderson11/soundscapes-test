import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SpotifyService {
  final String clientId = '0b1ad9e7e5a343fd9616ab65465cf91e';
  final String clientSecret = '67db597e63594d9ea11ccfad94cd0c37';

  final List<String> commonQualities = ['Low', 'Medium', 'High'];
  final List<String> specialQualities = ['Low', 'Medium', 'High', 'CDQ', 'HR'];

  String? _accessToken;
  DateTime? _tokenExpirationTime;

  Future<String> _getAccessToken() async {
    if (_accessToken != null && _tokenExpirationTime!.isAfter(DateTime.now())) {
      return _accessToken!;
    }

    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: 'grant_type=client_credentials',
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      _accessToken = responseBody['access_token'];
      _tokenExpirationTime =
          DateTime.now().add(Duration(seconds: responseBody['expires_in']));
      return _accessToken!;
    } else {
      throw Exception('Failed to get access token');
    }
  }

  Future<Map<String, String>> fetchRandomAlbumAndCacheNext(
      List<String> userArtists) async {
    final token = await _getAccessToken();

    // Fetch random artist and album
    final currentAlbum = await _fetchRandomArtistAndAlbum(token, userArtists);

    // Simultaneously cache the next artist's album
    _cacheNextArtistAlbum(token, userArtists);

    return currentAlbum;
  }

  Future<Map<String, String>> _fetchRandomArtistAndAlbum(
      String token, List<String> userArtists) async {
    bool chooseFavorite = Random().nextDouble() < .10; // 10%
    String artistId, artistName;

    if (chooseFavorite && userArtists.isNotEmpty) {
      final favoriteArtist = userArtists[Random().nextInt(userArtists.length)];
      final searchResponse = await http.get(
        Uri.parse(
            'https://api.spotify.com/v1/search?q=$favoriteArtist&type=artist&limit=1'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);
        final artists = searchData['artists']['items'] as List<dynamic>;
        if (artists.isNotEmpty) {
          final artist = artists[0];
          artistId = artist['id'];
          artistName = artist['name'];
        } else {
          return _emptyAlbum();
        }
      } else {
        return _emptyAlbum();
      }
    } else {
      String randomLetter = String.fromCharCode(Random().nextInt(26) + 97);
      final searchResponse = await http.get(
        Uri.parse(
            'https://api.spotify.com/v1/search?q=$randomLetter&type=artist&limit=50'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);
        final artists = searchData['artists']['items'] as List<dynamic>;
        if (artists.isNotEmpty) {
          final randomArtist = artists[Random().nextInt(artists.length)];
          artistId = randomArtist['id'];
          artistName = randomArtist['name'];
        } else {
          return _emptyAlbum();
        }
      } else {
        return _emptyAlbum();
      }
    }

    // Fetch a random album for the selected artist
    return await _getRandomAlbumForArtist(artistId, token);
  }

  Future<void> _cacheNextArtistAlbum(
      String token, List<String> userArtists) async {
    await _fetchRandomArtistAndAlbum(token, userArtists);
  }

  Future<Map<String, String>> _getRandomAlbumForArtist(
      String artistId, String token) async {
    final albums = await _getAlbumsForArtist(artistId, token, 50);

    if (albums.isNotEmpty) {
      final randomAlbum = albums[Random().nextInt(albums.length)];
      String albumArtUrl = randomAlbum['images'] != null &&
              randomAlbum['images'].isNotEmpty
          ? randomAlbum['images'][0]['url'].replaceFirst('http://', 'https://')
          : '';

      return {
        'albumId': randomAlbum['id'],
        'albumName': randomAlbum['name'],
        'albumArt': albumArtUrl,
      };
    }

    return _emptyAlbum();
  }

  Future<List<Map<String, dynamic>>> _getAlbumsForArtist(
      String artistId, String token, int limit) async {
    List<Map<String, dynamic>> albums = [];
    int offset = 0;

    while (true) {
      final albumsResponse = await http.get(
        Uri.parse(
            'https://api.spotify.com/v1/artists/$artistId/albums?limit=$limit&offset=$offset'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (albumsResponse.statusCode != 200) break;

      final albumsData = jsonDecode(albumsResponse.body);
      final items = albumsData['items'] as List<dynamic>;

      if (items.isEmpty) break;

      albums
          .addAll(items.map((album) => album as Map<String, dynamic>).toList());

      if (items.length < limit) break;
      offset += limit;
    }

    return albums;
  }

  Map<String, String> _emptyAlbum() {
    return {
      'albumId': '',
      'albumName': 'Unknown Album',
      'albumArt': '',
    };
  }

  Future<Map<String, String>> fetchArtistInfo(String artistId) async {
    final token = await _getAccessToken();
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/artists/$artistId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'name': data['name'],
        'followers': data['followers']['total'].toString(),
        'genres': (data['genres'] as List).join(', '),
        'image': data['images'].isNotEmpty
            ? data['images'][0]['url']
            : '', // Use the first image if available
      };
    } else {
      throw Exception('Failed to load artist information');
    }
  }

  Future<Song> fetchRandomSongFromAlbum(String albumId) async {
    final token = await _getAccessToken();

    final albumResponse = await http.get(
      Uri.parse('https://api.spotify.com/v1/albums/$albumId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (albumResponse.statusCode == 200) {
      final albumData = jsonDecode(albumResponse.body);
      final albumName = albumData['name'];
      final albumArtUrl = albumData['images'] != null &&
              albumData['images'].isNotEmpty
          ? albumData['images'][0]['url'].replaceFirst('http://', 'https://')
          : '';

      final tracks = albumData['tracks']['items'] as List<dynamic>;
      final randomTrack = tracks[Random().nextInt(tracks.length)];
      final trackName = randomTrack['name'] ?? 'Unknown Track';

      final artistId = randomTrack['artists'][0]['id'];
      final artistName = randomTrack['artists'][0]['name'] ?? 'Unknown Artist';

      final randomQuality =
          commonQualities[Random().nextInt(commonQualities.length)];

      return Song(
        artistId: artistId,
        artist: artistName,
        track: trackName,
        albumArt: albumArtUrl,
        quality: randomQuality,
        albumName: albumName,
      );
    } else {
      return Song(
        artistId: '',
        artist: 'Unknown Artist',
        track: 'No song found',
        albumArt: '',
        quality: 'Unknown',
        albumName: 'Unknown Album',
      );
    }
  }
}

@immutable
class Song {
  String artistId;
  String artist;
  String track;
  String albumArt;
  String quality;
  String albumName;

  Song(
      {required this.artistId,
      required this.artist,
      required this.track,
      required this.albumArt,
      required this.quality,
      required this.albumName});

  Song.fromJson(Map<String, dynamic> json)
      : artistId = json['artistId'],
        artist = json['artist'],
        track = json['track'],
        albumArt = json['albumArt'],
        quality = json['quality'],
        albumName = json['albumName'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['artistId'] = artistId;
    data['artist'] = artist;
    data['track'] = track;
    data['albumArt'] = albumArt;
    data['quality'] = quality;
    data['albumName'] = albumName;
    return data;
  }
}
