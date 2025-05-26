import 'package:flutter/material.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';
import '../data/tracks_data.dart';
import '../services/audio_player_service.dart';
import '../screens/player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Track> _trendingTracks;
  late List<Track> _newReleaseTracks;
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  @override
  void initState() {
    super.initState();
    _trendingTracks = TracksData.trendingTracks;
    _newReleaseTracks = TracksData.newReleaseTracks;
  }

  @override
  void dispose() {
    super.dispose();
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
      bottomNavigationBar: _buildNowPlayingBar(),
    );
  }

  Widget _buildNowPlayingBar() {
    return StreamBuilder<bool>(
      stream: _audioPlayerService.audioPlayer.playingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        final currentTrack = _audioPlayerService.currentTrack;

        if (currentTrack == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerScreen(track: currentTrack),
              ),
            );
          },
          child: Container(
            height: 70,
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: Image.network(
                  currentTrack.coverUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey,
                      child: const Icon(Icons.music_note, color: Colors.white),
                    );
                  },
                ),
              ),
              title: Text(currentTrack.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(currentTrack.artist),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 32,
                    ),
                    onPressed: () {
                      if (isPlaying) {
                        _audioPlayerService.pauseTrack();
                      } else {
                        _audioPlayerService.playTrack(currentTrack);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
