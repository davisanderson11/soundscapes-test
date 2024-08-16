import 'package:flutter/material.dart';
import 'package:music_game/spotify_service.dart';
import 'package:music_game/map_screen.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> userArtists = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showArtistInputDialog();
    });
  }

  void _showArtistInputDialog() async {
    final List<TextEditingController> controllers =
        List.generate(5, (_) => TextEditingController());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter 5 Favorite Artists"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (index) => TextField(
                controller: controllers[index],
                decoration: InputDecoration(labelText: 'Artist ${index + 1}'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  userArtists =
                      controllers.map((controller) => controller.text).toList();
                });
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MapScreen(userArtists: userArtists);
  }
}
