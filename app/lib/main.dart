import 'package:flutter/material.dart';
import 'package:music_game/app.dart';
import 'package:client/client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

var client = Client('http://localhost:8080/')..connectivityMonitor = FlutterConnectivityMonitor();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      home: const App(),
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false));
}
