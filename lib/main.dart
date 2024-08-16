import 'package:flutter/material.dart';
import 'package:music_game/my_app.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure binding is initialized before async calls
  runApp(MaterialApp(
    home: MyApp(), // Wrap MyApp in MaterialApp
  ));
}
