import 'package:flutter/material.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Örnek veri
  final List<Track> _trendingTracks = [
    Track(
      id: '1',
      title: 'Boş Sokak',
      artist: 'Cem Karaca',
      coverUrl: 'https://via.placeholder.com/300',
      audioUrl: 'https://example.com/audio1.mp3',
      duration: 240,
      playCount: 12500,
    ),
    Track(
      id: '2',
      title: 'Sen Ağlama',
      artist: 'Sezen Aksu',
      coverUrl: 'https://via.placeholder.com/300',
      audioUrl: 'https://example.com/audio2.mp3',
      duration: 198,
      playCount: 8700,
    ),
    Track(
      id: '3',
      title: 'Gülpembe',
      artist: 'Barış Manço',
      coverUrl: 'https://via.placeholder.com/300',
      audioUrl: 'https://example.com/audio3.mp3',
      duration: 320,
      playCount: 15800,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Trend Parçalar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _trendingTracks.length,
            itemBuilder: (context, index) {
              return TrackTile(track: _trendingTracks[index]);
            },
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Yeni Çıkanlar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Yeni çıkanlar kısmı da eklenecek
        ],
      ),
    );
  }
}
