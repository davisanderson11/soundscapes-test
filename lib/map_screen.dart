import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:music_game/spotify_service.dart';
import 'package:music_game/profile_screen.dart';
import 'package:music_game/artist_info_screen.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert'; // Import this for JSON encoding/decoding

class MapScreen extends StatefulWidget {
  List<String> userArtists;

  MapScreen({required this.userArtists});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  List<Map<String, String>> _clickedSongs = [];
  List<Marker>? _markers;
  MapController _mapController = MapController();

  late BuildContext _parentContext;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _loadClickedSongs(); // Load songs from storage when the app starts
  }

  Future<void> _loadClickedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final clickedSongsString = prefs.getString('clicked_songs');
    if (clickedSongsString != null) {
      setState(() {
        _clickedSongs =
            List<Map<String, String>>.from(json.decode(clickedSongsString));
      });
    }
  }

  Future<void> _saveClickedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('clicked_songs', json.encode(_clickedSongs));
  }

  Future<void> _initializeMarkers() async {
    LatLng userLocation = await _getCurrentLocation(context);
    List<Marker> markers = [];

    for (int i = 0; i < 100; i++) {
      LatLng randomPoint = getRandomLatLng(userLocation, 0.01);
      final isSpecialDrop =
          Random().nextDouble() < 0.10; // 10% chance for special drop

      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: randomPoint,
          builder: (ctx) => GestureDetector(
            onTap: () => _onMarkerTapped(isSpecialDrop),
            child: Container(
              child: Icon(
                isSpecialDrop ? Icons.star : Icons.music_note,
                color: isSpecialDrop ? Colors.purple : Colors.blue,
                size: 40,
              ),
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<LatLng> _getCurrentLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionDialog(context);
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    return LatLng(position.latitude, position.longitude);
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Location Permission Required"),
          content: Text(
              "Location permissions are permanently denied. Please enable them in the app settings."),
          actions: <Widget>[
            TextButton(
              child: Text("Open Settings"),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  LatLng getRandomLatLng(LatLng center, double offset) {
    final random = Random();
    final lat = center.latitude + (random.nextDouble() * (offset * 2) - offset);
    final lng =
        center.longitude + (random.nextDouble() * (offset * 2) - offset);
    return LatLng(lat, lng);
  }

  LatLngBounds _getBoundsForMarkers(List<Marker> markers) {
    double? minLat, maxLat, minLng, maxLng;

    for (var marker in markers) {
      if (minLat == null || marker.point.latitude < minLat) {
        minLat = marker.point.latitude;
      }
      if (maxLat == null || marker.point.latitude > maxLat) {
        maxLat = marker.point.latitude;
      }
      if (minLng == null || marker.point.longitude < minLng) {
        minLng = marker.point.longitude;
      }
      if (maxLng == null || marker.point.longitude > maxLng) {
        maxLng = marker.point.longitude;
      }
    }

    return LatLngBounds(LatLng(minLat!, minLng!), LatLng(maxLat!, maxLng!));
  }

  void _onMarkerTapped(bool isSpecialDrop) async {
    final randomAlbum =
        await _spotifyService.fetchRandomAlbumAndCacheNext(widget.userArtists);

    // Display the album details in a dialog
    showDialog(
      context: _parentContext,
      builder: (context) => AlertDialog(
        title: Text(randomAlbum['albumName'] ?? 'Unknown Album'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((randomAlbum['albumArt'] ?? '').isNotEmpty)
              GestureDetector(
                onTap: () => _selectRandomSong(randomAlbum['albumId'] ?? ''),
                child: Image.network(
                  randomAlbum['albumArt']!,
                  width: 150,
                  height: 150,
                ),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Navigator.of(_parentContext).pop();
            },
          ),
        ],
      ),
    );
  }

  void _selectRandomSong(String albumId) async {
    if (!mounted) return;

    // Close the album dialog before showing the song dialog
    Navigator.of(_parentContext).pop();

    // Show loading indicator
    showDialog(
      context: _parentContext,
      builder: (context) => Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    // Fetch song data using the album ID and get the album art and album name
    final randomSong = await _spotifyService.fetchRandomSongFromAlbum(albumId);

    if (!mounted) return;

    // Close the loading indicator
    Navigator.of(_parentContext).pop();

    if (!mounted) return;

    // Add the song to the list of clicked songs
    setState(() {
      _clickedSongs.insert(0, randomSong); // Add newest song at the top
      _saveClickedSongs(); // Save the updated list to local storage
    });

    // Use the album art from the returned data
    String albumArt = randomSong['albumArt'] ?? '';

    // Determine the color based on the quality
    Color getQualityColor(String quality) {
      switch (quality) {
        case 'Low':
          return Colors.red;
        case 'Medium':
          return Colors.orange;
        case 'High':
          return Colors.yellow;
        case 'CD':
          return Colors.green;
        case 'HR':
          return Colors.blue;
        case 'Lossless':
          return Colors.purple;
        case 'Master':
          return Colors.black;
        default:
          return Colors.grey; // Fallback color
      }
    }

    // Show the song details using the album art and quality color
    showDialog(
      context: _parentContext,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        contentPadding: EdgeInsets.all(16.0),
        content: Container(
          width: 300,
          height:
              300, // Set the height and width to be equal to make it a square
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (albumArt.isNotEmpty)
                Image.network(
                  albumArt,
                  width: 150,
                  height: 150,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.broken_image,
                      size: 150,
                      color: Colors.grey,
                    );
                  },
                ),
              SizedBox(height: 10),
              Text(
                '${randomSong['track']}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: 5),
              GestureDetector(
                onTap: () {
                  if (randomSong['artistId'] != null) {
                    _navigateToArtistInfo(randomSong['artistId']!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Artist information not available')),
                    );
                  }
                },
                child: Text(
                  'by ${randomSong['artist'] ?? 'Unknown Artist'}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Roboto',
                    decoration: TextDecoration.underline,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: getQualityColor(randomSong['quality']!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  randomSong['quality']!,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Close',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            onPressed: () {
              Navigator.of(_parentContext).pop();
            },
          ),
        ],
      ),
    );
  }

  void _navigateToArtistInfo(String artistId) {
    Navigator.push(
      _parentContext,
      MaterialPageRoute(
        builder: (context) => ArtistInfoScreen(artistId: artistId),
      ),
    );
  }

  void _resetMapZoom() {
    LatLngBounds bounds = _getBoundsForMarkers(_markers!);
    _mapController.fitBounds(bounds,
        options: FitBoundsOptions(padding: EdgeInsets.all(20.0)));
  }

  void _showFavoritesDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final artists = prefs.getStringList('user_artists') ?? [];
    final controllers =
        List.generate(5, (i) => TextEditingController(text: artists[i]));

    await showDialog(
      context: _parentContext,
      builder: (context) {
        return AlertDialog(
          title: const Text("Your five favorite artists"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (index) {
                return TextFormField(
                    controller: controllers[index],
                    decoration:
                        InputDecoration(labelText: 'Artist ${index + 1}'));
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  final artists =
                      controllers.map((controller) => controller.text).toList();
                  prefs.setStringList('user_artists', artists);
                  widget.userArtists = artists;
                });
                Navigator.of(_parentContext).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Save the parent context
    _parentContext = context;

    return Scaffold(
      body: _markers == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    bounds: _getBoundsForMarkers(
                        _markers!), // Ensure all markers are visible
                    boundsOptions:
                        FitBoundsOptions(padding: EdgeInsets.all(20.0)),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(markers: _markers!),
                  ],
                ),
                Positioned(
                  bottom: 80, // Adjust to position above the Map button
                  left: 20,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _resetMapZoom,
                    child: Icon(Icons.zoom_out_map, color: Colors.blue),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          MapScreen(userArtists: widget.userArtists)),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text('Map'),
            ),
            ElevatedButton(
              onPressed: _showFavoritesDialog,
              child: Text('Favorites'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(clickedSongs: _clickedSongs),
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
