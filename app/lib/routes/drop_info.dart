import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' as spotify;

class DropInfoScreen extends StatefulWidget {
  final spotify.TrackSimple song;
  final spotify.Album album;
  final SongQuality quality;

  const DropInfoScreen(
      {required this.song,
      required this.album,
      required this.quality,
      super.key});

  @override
  State<DropInfoScreen> createState() => _DropInfoScreenState();
}

class _DropInfoScreenState extends State<DropInfoScreen> {
  // final SpotifyService _spotifyService = SpotifyService();
  // bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    // _loadArtistInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: SizedBox(
          width: 300,
          height: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                widget.album.images!.first.url!,
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  size: 150,
                  Icons.broken_image,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.song.name ?? '',
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
                  // if (widget.song.artists?.first.id != null) {
                  //   _navigateToArtistInfo(widget.song.artists!.first.id!);
                  // } else {
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     const SnackBar(
                  //         content: Text('Artist information not available')),
                  //   );
                  // }
                },
                child: Text(
                  'by ${widget.song.artists?.map((artist) => artist.name).join(', ')}',
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
                  color: widget.quality.getColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.quality.getName(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}

final weights = {
  SongQuality.low: 95,
  SongQuality.medium: 5,
  SongQuality.high: 0,
  SongQuality.cd: 0,
  SongQuality.hr: 0,
  SongQuality.lossless: 0,
  SongQuality.master: 0
};

enum SongQuality {
  low,
  medium,
  high,
  cd,
  hr,
  lossless,
  master;

  Color getColor() {
    return {
      'low': const Color(0xFF6e6e6e),
      'medium': const Color(0xFFc28325),
      'high': const Color(0xFFe0e0e0),
      'cd': const Color(0xFFffcf40),
      'hr': const Color(0xFFdebee6),
      'lossless': Colors.purple,
      'master': Colors.black
    }[name]!;
  }

  String getName() {
    return {
      'low': 'Low',
      'medium': 'Medium',
      'high': 'High',
      'cd': 'CD',
      'hr': 'HR',
      'lossless': 'Lossless',
      'master': 'Master'
    }[name]!;
  }
}
