import 'package:flutter/material.dart';
import 'package:music_game/map_screen.dart';

class ProfileScreen extends StatelessWidget {
  final List<Map<String, String>> clickedSongs;

  ProfileScreen({required this.clickedSongs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: clickedSongs.isEmpty
          ? Center(child: Text('No songs collected yet.'))
          : ListView.builder(
              itemCount: clickedSongs.length,
              itemBuilder: (context, index) {
                final song = clickedSongs[index];
                return ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  leading: song['albumArt']!.isNotEmpty
                      ? Image.network(song['albumArt']!, width: 50, height: 50)
                      : Icon(Icons.music_note, size: 50),
                  title: Text(
                    song['track'] ?? 'Unknown Track',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'by ${song['artist'] ?? 'Unknown Artist'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      song['quality'] ?? 'Unknown',
                      style: TextStyle(
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
                      builder: (context) => MapScreen(userArtists: [])),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text('Map'),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement the Favorites button action if needed
              },
              child: Text('Favorites'),
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
              child: Text('Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
