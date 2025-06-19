import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ana Sayfa',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: const [],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tracks')
            .orderBy('releaseDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Hiç şarkı yok.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onBackground,
                ),
              ),
            );
          }

          final tracks = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Track(
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
          }).toList();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_audioPlayerService.currentPlaylist.isEmpty &&
                tracks.isNotEmpty) {
              _audioPlayerService.setPlaylist(tracks, 0);
            }
          });

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Tüm Şarkılar',
                  style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onBackground,
                      fontWeight: FontWeight.bold),
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
                    onTap: () {
                      _audioPlayerService.setPlaylist(tracks, index);
                      _audioPlayerService.playTrack(track);
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
