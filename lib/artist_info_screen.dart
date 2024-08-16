import 'package:flutter/material.dart';
import 'package:music_game/spotify_service.dart';

class ArtistInfoScreen extends StatefulWidget {
  final String artistId;

  ArtistInfoScreen({required this.artistId});

  @override
  _ArtistInfoScreenState createState() => _ArtistInfoScreenState();
}

class _ArtistInfoScreenState extends State<ArtistInfoScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  bool _isLoading = true;
  Map<String, String>? _artistInfo;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArtistInfo();
  }

  Future<void> _loadArtistInfo() async {
    try {
      _artistInfo =
          await _spotifyService.fetchArtistInfo(widget.artistId).timeout(
        Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Artist Information'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _artistInfo!['image']!.isNotEmpty
                          ? Image.network(_artistInfo!['image']!)
                          : SizedBox.shrink(),
                      SizedBox(height: 20),
                      Text(
                        _artistInfo!['name']!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Followers: ${_artistInfo!['followers']}',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Genres: ${_artistInfo!['genres']}',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
    );
  }
}
