import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:music_game/services/spotify.dart';
import 'package:music_game/routes/drop_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:spotify/spotify.dart' as spotify;
import 'package:music_game/main.dart' show client;
import 'dart:ui';
import 'dart:math';
import 'dart:convert';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin {
  final SpotifyService _spotify = SpotifyService();
  List<Marker>? _markers;
  final MapController _mapController = MapController();

  List<spotify.TrackSimple> _songCollection = [];
  List<String> _userArtists = [];

  late BuildContext _parentContext;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _loadSongCollection();
    _loadUserArtists();
  }

  @override
  get wantKeepAlive => true;

  Future<void> _loadUserArtists() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userArtists = prefs.getStringList('user_artists') ?? []);
  }

  Future<void> _loadSongCollection() async {
    final prefs = await SharedPreferences.getInstance();
    final songCollectionStrings = prefs.getStringList('song_collection');
    if (songCollectionStrings != null) {
      setState(() {
        _songCollection = songCollectionStrings
            .map((str) => spotify.TrackSimple.fromJson(json.decode(str)))
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
          point: point,
          child: GestureDetector(
            onTap: () => _onMarkerTapped(special),
            child: Opacity(
                opacity: 0.7,
                child: Icon(special ? Icons.star : Icons.music_note,
                    color: special ? Colors.purple : Colors.blue, size: 30)),
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
    final album = await _spotify.fetchRandomAlbum(_userArtists);
    final tracks = await _spotify.albums.tracks(album!.id!).all(50);
    if (tracks.isEmpty) {
      throw 'No tracks (${album.name!} by ${album.artists!.first.name})';
    }

    final cover = album.images?.first.url ?? '';
    final track = tracks.elementAt(Random().nextInt(tracks.length));
    final quality = SongQuality
        .values[Random().nextInt(SongQuality.values.length)]; // FIXME: weights

    _songCollection.add(track);
    _saveSongCollection();

    if (!mounted) return;
    showDialog(
      context: _parentContext,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(0, 60, 0, 60),
        content: ImageFiltered(
            imageFilter: ImageFilter.blur(
                sigmaX: 10, sigmaY: 10, tileMode: TileMode.mirror),
            child: Image.network(cover, width: 100, height: 100)), //),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            child: const Text('Open'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => DropInfoScreen(
                      song: track, album: album, quality: quality)));
            },
          ),
        ],
      ),
    );
  }

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
    super.build(context);
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
                  heroTag: 'favorites',
                  onPressed: _showFavoritesDialog,
                  child: const Icon(Icons.star /*, color: Colors.blue*/),
                ),
              ),
              Positioned(
                  top: 20,
                  right: 20,
                  child: FloatingActionButton(
                      mini: true,
                      heroTag: 'profile',
                      onPressed:
                          _showFavoritesDialog, // FIXME: need profile page to switch to
                      child: const Icon(Icons.person)))
            ],
          );
  }
}
