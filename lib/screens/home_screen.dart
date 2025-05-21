import 'package:flutter/material.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';
import '../models/tracks_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Track> _trendingTracks;
  late List<Track> _newReleaseTracks;

  @override
  void initState() {
    super.initState();
    _trendingTracks = TracksData.trendingTracks;
    _newReleaseTracks = TracksData.newReleaseTracks;
  }

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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _newReleaseTracks.length,
            itemBuilder: (context, index) {
              return TrackTile(track: _newReleaseTracks[index]);
            },
          ),
        ],
      ),
    );
  }
}
