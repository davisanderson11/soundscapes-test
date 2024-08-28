import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify/spotify.dart' as spotify;
import 'package:music_game/services/spotify.dart';
import 'dart:convert';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<spotify.Track> _songCollection = [];
  final SpotifyService _spotify = SpotifyService();

  _CollectionScreenState();

  @override
  initState() {
    super.initState();
    _loadSongCollection();
  }

  _loadSongCollection() async {
    final prefs = await SharedPreferences.getInstance();
    final songCollectionStrings = prefs.getStringList('song_collection');
    if (songCollectionStrings != null) {
      final simpleSongCollection = songCollectionStrings
          .map((str) => spotify.TrackSimple.fromJson(json.decode(str)))
          .toList()
          .reversed;
      final songCollection = await _spotify.tracks.list(simpleSongCollection
          .where((song) => song.id != null)
          .map((song) => song.id!)
          .toList());

      setState(() {
        _songCollection = songCollection.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _songCollection.isEmpty
          ? const Center(child: Text('No songs collected yet.'))
          : ListView.builder(
              itemCount: _songCollection.length,
              itemBuilder: (context, index) {
                final song = _songCollection[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  leading: Image.network(song.album!.images!.first.url!,
                      width: 50, height: 50),
                  // : const Icon(Icons.music_note, size: 50),
                  title: Text(
                    song.name!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artists!.map((artist) => artist.name!).join(', '),
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Unknown', //song['quality'] ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight
                            .bold, //FIXME: not displaying song quality
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
