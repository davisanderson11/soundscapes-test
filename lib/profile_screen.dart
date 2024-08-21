import 'package:flutter/material.dart';
import 'package:music_game/map_screen.dart';

class ProfileScreen extends StatelessWidget {
  final List<Map<String, String>> clickedSongs;

  const ProfileScreen({required this.clickedSongs, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: clickedSongs.isEmpty
          ? const Center(child: Text('No songs collected yet.'))
          : ListView.builder(
              itemCount: clickedSongs.length,
              itemBuilder: (context, index) {
                final song = clickedSongs[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  leading: song['albumArt']!.isNotEmpty
                      ? Image.network(song['albumArt']!, width: 50, height: 50)
                      : const Icon(Icons.music_note, size: 50),
                  title: Text(
                    song['track'] ?? 'Unknown Track',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'by ${song['artist'] ?? 'Unknown Artist'}',
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
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      song['quality'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        color: Colors.grey,
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MapScreen(userArtists: [])),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Map'),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement the Favorites button action if needed
              },
              child: const Text('Favorites'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(clickedSongs: clickedSongs),
                  ),
                );
              },
              child: const Text('Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
