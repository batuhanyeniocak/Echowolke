import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';
import '../services/audio_player_service.dart';
import '../screens/player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  String _formatDuration(int seconds) {
    if (seconds.isNaN || seconds < 0) return '00:00';
    Duration duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tracks').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Hiç şarkı yok.'));
          }

          final tracks = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final track = Track(
              id: data['id'] ?? '',
              title: data['title'] ?? '',
              artist: data['artist'] ?? '',
              audioUrl: data['audioUrl'] ?? '',
              coverUrl: data['coverUrl'] ?? '',
              duration: data['duration'] ?? 0,
              playCount: data['playCount'] ?? 0,
              releaseDate: data['releaseDate'] != null
                  ? (data['releaseDate'] as Timestamp).toDate()
                  : DateTime.now(),
            );
            print('Track: ${track.title}, Cover URL: ${track.coverUrl}');
            return track;
          }).toList();

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tüm Şarkılar',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return TrackTile(
                    track: track,
                    formattedDuration: _formatDuration(track.duration),
                  );
                },
              ),
            ],
          );
        },
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
