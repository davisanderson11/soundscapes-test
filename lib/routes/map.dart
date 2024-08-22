import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:music_game/spotify_service.dart';
import 'package:music_game/artist_info_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'dart:math';
import 'dart:convert';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  List<Song> _songCollection = [];
  List<Marker>? _markers;
  final MapController _mapController = MapController();
  List<String> userArtists = [];

  late BuildContext _parentContext;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _loadSongCollection();
    _loadUserArtists();
  }

  Future<void> _loadUserArtists() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userArtists = prefs.getStringList('user_artists') ?? []);
  }

  Future<void> _loadSongCollection() async {
    final prefs = await SharedPreferences.getInstance();
    final songCollectionStrings = prefs.getStringList('song_collection');
    // print(clickedSongsString);
    if (songCollectionStrings != null) {
      setState(() {
        _songCollection = songCollectionStrings
            .map((str) => Song.fromJson(json.decode(str)))
            .toList();
      });
    }
  }

  Future<void> _saveSongCollection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('song_collection',
        _songCollection.map((song) => json.encode(song.toJson())).toList());
  }

  Future<void> _initializeMarkers() async {
    LatLng userLocation = await _getCurrentLocation(context);
    List<Marker> markers = [];

    for (int i = 0; i < 20; i++) {
      LatLng randomPoint = getRandomLatLng(userLocation, 0.01);
      final isSpecialDrop =
          Random().nextDouble() < 0.10; // 10% chance for special drop

      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: randomPoint,
          child: GestureDetector(
            onTap: () => _onMarkerTapped(isSpecialDrop),
            child: Opacity(
                opacity: 0.7,
                child: Icon(isSpecialDrop ? Icons.star : Icons.music_note,
                    color: isSpecialDrop ? Colors.purple : Colors.blue,
                    size: 40)),
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
      if (context.mounted) _showPermissionDialog(context);
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Permission Required"),
          content: const Text(
              "Location permissions are permanently denied. Please enable them in the app settings."),
          actions: <Widget>[
            TextButton(
              child: const Text("Open Settings"),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
            TextButton(
              child: const Text("Cancel"),
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
        await _spotifyService.fetchRandomAlbumAndCacheNext(userArtists);

    if (!mounted) return;
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
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
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
      builder: (context) => const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    // Fetch song data using the album ID and get the album art and album name
    final randomSong = await _spotifyService.fetchRandomSongFromAlbum(albumId);

    if (!mounted) return;

    // Close the loading indicator
    Navigator.of(_parentContext).pop();

    // Add the song to the list of clicked songs
    setState(() {
      _songCollection.insert(0, randomSong);
      _saveSongCollection();
    });

    // Use the album art from the returned data
    String albumArt = randomSong.albumArt;

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
          return Colors.grey;
      }
    }

    // Show the song details using the album art and quality color
    showDialog(
      context: _parentContext,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (albumArt.isNotEmpty)
                Image.network(
                  albumArt,
                  width: 150,
                  height: 150,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image,
                      size: 150,
                      color: Colors.grey,
                    );
                  },
                ),
              const SizedBox(height: 10),
              Text(
                randomSong.track,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () {
                  // FIXME
                  if (randomSong.artistId != null) {
                    _navigateToArtistInfo(randomSong.artistId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Artist information not available')),
                    );
                  }
                },
                child: Text(
                  // FIXME
                  'by ${randomSong.artist ?? 'Unknown Artist'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: getQualityColor(randomSong.quality),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  randomSong.quality,
                  style: const TextStyle(
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
            child: const Text(
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
    _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(20)));
  }

  void _showFavoritesDialog() async {
    final controllers =
        List.generate(5, (i) => TextEditingController(text: userArtists[i]));
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
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
                final artists = controllers.map((ctrl) => ctrl.text).toList();
                prefs.setStringList('user_artists', artists);
                setState(() => userArtists = artists);
                Navigator.of(context).pop();
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
    final theme = Theme.of(context).brightness.name;

    return _markers == null
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  initialCameraFit: CameraFit.bounds(
                      bounds: _getBoundsForMarkers(_markers!),
                      padding: const EdgeInsets.all(20)),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.basemaps.cartocdn.com/${theme}_all/{z}/{x}/{y}{r}.png",
                    subdomains: const ['a', 'b', 'c'],
                    retinaMode: RetinaMode.isHighDensity(context),
                  ),
                  MarkerLayer(markers: _markers!),
                  CurrentLocationLayer(
                      style: LocationMarkerStyle(
                          headingSectorColor: Colors.red,
                          headingSectorRadius: 120,
                          marker: DefaultLocationMarker(
                              color: Colors.blue.shade900)))
                ],
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: _showFavoritesDialog,
                  child: const Icon(Icons.star /*, color: Colors.blue*/),
                ),
              ),
            ],
          );
  }
}
