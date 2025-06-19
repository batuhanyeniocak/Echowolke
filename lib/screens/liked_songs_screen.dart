import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/services/firebase_service.dart';
import 'package:flutter_app/services/audio_player_service.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';

class LikedSongsScreen extends StatefulWidget {
  const LikedSongsScreen({Key? key}) : super(key: key);

  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen> {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  String _formatDuration(int seconds) {
    if (seconds.isNaN || seconds < 0) return '00:00';
    Duration duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _removeLikedSong(String trackId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await Provider.of<FirebaseService>(context, listen: false)
            .removeLikedSong(currentUser.uid, trackId);
        if (mounted) {}
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Kaldırılırken hata oluştu: $e'),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Beğenilen Şarkılar',
              style:
                  textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
          backgroundColor: colorScheme.surface,
          elevation: 0,
        ),
        body: Center(
          child: Text('Beğenilen şarkıları görmek için giriş yapmalısınız.',
              style: textTheme.bodyLarge
                  ?.copyWith(color: colorScheme.onBackground)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Beğenilen Şarkılar',
            style:
                textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: StreamBuilder<List<Track>>(
        stream: firebaseService.getLikedSongs(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary)));
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Hata: ${snapshot.error}',
                    style: textTheme.bodyLarge
                        ?.copyWith(color: colorScheme.error)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text('Henüz beğenilen şarkınız yok.',
                    style: textTheme.bodyLarge
                        ?.copyWith(color: colorScheme.onBackground)));
          }

          final likedTracks = snapshot.data!;

          return ListView.builder(
            itemCount: likedTracks.length,
            itemBuilder: (context, index) {
              final track = likedTracks[index];
              return TrackTile(
                track: track,
                formattedDuration: _formatDuration(track.duration),
                onTap: () {
                  _audioPlayerService.setPlaylist(likedTracks, index);
                  _audioPlayerService.playTrack(track);
                },
                trailingWidget: IconButton(
                  icon: Icon(Icons.favorite, color: colorScheme.primary),
                  onPressed: () => _removeLikedSong(track.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
