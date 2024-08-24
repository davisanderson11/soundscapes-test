import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:music_game/services/spotify.dart';
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
  List<Marker>? _markers;
  final MapController _mapController = MapController();

  List<Song> _songCollection = [];
  List<String> _userArtists = [];

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
    setState(() => _userArtists = prefs.getStringList('user_artists') ?? []);
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

  Future<void> _saveUserArtists() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('user_artists', _userArtists);
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
      final point = _getRandomLatLng(userLocation, 0.01);
      final special = Random().nextDouble() < .10; // 10%

      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: point,
          child: GestureDetector(
            onTap: () => _onMarkerTapped(special),
            child: Opacity(
                opacity: 0.7,
                child: Icon(special ? Icons.star : Icons.music_note,
                    color: special ? Colors.purple : Colors.blue, size: 40)),
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
    } else if (permission == LocationPermission.deniedForever) {
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

  LatLng _getRandomLatLng(LatLng center, double offset) {
    final random = Random();
    final lat = center.latitude + (random.nextDouble() * (offset * 2) - offset);
    final lng =
        center.longitude + (random.nextDouble() * (offset * 2) - offset);
    return LatLng(lat, lng);
  }

  LatLngBounds _getBoundsForMarkers(List<Marker> markers) {
    var minLat = markers.map((marker) => marker.point.latitude).reduce(min);
    var maxLat = markers.map((marker) => marker.point.latitude).reduce(max);
    var minLng = markers.map((marker) => marker.point.longitude).reduce(min);
    var maxLng = markers.map((marker) => marker.point.longitude).reduce(max);
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  void _onMarkerTapped(bool isSpecialDrop) async {
    final randomAlbum =
        await _spotifyService.fetchRandomAlbumAndCacheNext(_userArtists);

    if (!mounted) return;
    showDialog(
      context: _parentContext,
      builder: (context) => AlertDialog(
        title: Text(randomAlbum?.name ?? 'Unknown album'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((randomAlbum?.cover ?? '').isNotEmpty)
              GestureDetector(
                onTap: () => _selectRandomSong(randomAlbum.id, context),
                child: Image.network(
                  randomAlbum!.cover,
                  width: 150,
                  height: 150,
                ),
              ),
          ],
        ),
        actions: [
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

  void _selectRandomSong(String albumId, BuildContext context) async {
    // Close the album dialog before showing the song dialog
    Navigator.of(context).pop();

    BuildContext? _loadingDialogContext;

    // Show loading indicator
    showDialog(
      context: _parentContext,
      builder: (context) {
        _loadingDialogContext = context;
        return const Center(child: CircularProgressIndicator());
      },
      barrierDismissible: false,
    );

    // Fetch song data using the album ID and get the album art and album name
    final randomSong = await _spotifyService.fetchRandomSongFromAlbum(albumId);

    if (!_loadingDialogContext!.mounted) return;

    // Close the loading indicator
    Navigator.of(_loadingDialogContext!).pop();

    // Add the song to the list of clicked songs
    setState(() {
      if (randomSong == null) return;
      _songCollection.insert(0, randomSong);
      _saveSongCollection();
    });

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
              if (randomSong?.albumArt != null &&
                  randomSong!.albumArt.isNotEmpty)
                Image.network(
                  randomSong.albumArt,
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
                randomSong?.track ?? '',
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
                  if (randomSong?.artistId != null) {
                    _navigateToArtistInfo(randomSong!.artistId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Artist information not available')),
                    );
                  }
                },
                child: Text(
                  'by ${randomSong?.artist ?? 'Unknown Artist'}',
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
                  color: getQualityColor(randomSong?.quality ?? 'Low'),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  randomSong?.quality ?? 'Low',
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
        actions: [
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

  void _navigateToArtistInfo(String artistId) {
    Navigator.of(_parentContext).push(
      MaterialPageRoute(
        builder: (context) => ArtistInfoScreen(artistId: artistId),
      ),
    );
  }

  // void _resetMapZoom() {
  //   LatLngBounds bounds = _getBoundsForMarkers(_markers!);
  //   _mapController.fitCamera(
  //       CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(20)));
  // }

  void _showFavoritesDialog() async {
    final controllers =
        List.generate(5, (i) => TextEditingController(text: _userArtists[i]));

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
                setState(() {
                  _userArtists = controllers.map((ctrl) => ctrl.text).toList();
                });
                _saveUserArtists();
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
