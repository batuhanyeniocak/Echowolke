import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/services/firebase_service.dart';
import 'package:flutter_app/models/track.dart';
import 'package:flutter_app/widgets/track_tile.dart';
import 'package:flutter_app/services/audio_player_service.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Beğenilen Şarkılar'),
          backgroundColor: Colors.orange,
        ),
        body: const Center(
          child: Text('Beğenilen şarkıları görmek için giriş yapmalısınız.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beğenilen Şarkılar'),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: StreamBuilder<List<Track>>(
        stream: firebaseService.getLikedSongs(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz beğenilen şarkınız yok.'));
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
              );
            },
          );
        },
      ),
    );
  }
}
