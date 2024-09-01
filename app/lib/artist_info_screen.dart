import 'package:flutter/material.dart';
import 'package:app/services/spotify.dart';
import 'package:spotify/spotify.dart' as spotify;

class ArtistInfoScreen extends StatefulWidget {
  final String artistId;

  const ArtistInfoScreen({required this.artistId, super.key});

  @override
  State<ArtistInfoScreen> createState() => _ArtistInfoScreenState();
}

class _ArtistInfoScreenState extends State<ArtistInfoScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  bool _isLoading = true;
  spotify.Artist? _artistInfo;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArtistInfo();
  }

  Future<void> _loadArtistInfo() async {
    try {
      _artistInfo = await _spotifyService.artists.get(widget.artistId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Information'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _artistInfo!.images?.first.url?.isNotEmpty ?? true
                          ? Image.network(_artistInfo!.images!.first.url!)
                          : const SizedBox.shrink(),
                      const SizedBox(height: 20),
                      Text(
                        _artistInfo!.name!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Followers: ${_artistInfo!.followers!}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Genres: ${_artistInfo!.genres}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
    );
  }
}
