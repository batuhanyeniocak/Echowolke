import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../services/firebase_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/track_tile.dart';
import 'public_profile_screen.dart';

class PublicPlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PublicPlaylistDetailScreen({required this.playlist, Key? key})
      : super(key: key);

  @override
  _PublicPlaylistDetailScreenState createState() =>
      _PublicPlaylistDetailScreenState();
}

class _PublicPlaylistDetailScreenState
    extends State<PublicPlaylistDetailScreen> {
  late Future<Map<String, dynamic>> _playlistDataFuture;

  @override
  void initState() {
    super.initState();
    _playlistDataFuture = _loadPlaylistData();
  }

  Future<Map<String, dynamic>> _loadPlaylistData() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    try {
      final tracksFuture =
          firebaseService.getTracksByIds(widget.playlist.trackIds);
      final creatorFuture =
          firebaseService.getUserData(widget.playlist.creatorId);

      final results = await Future.wait([tracksFuture, creatorFuture]);

      return {
        'tracks': results[0] as List<Track>,
        'creator': results[1] as Map<String, dynamic>?,
      };
    } catch (e) {
      throw Exception("Liste verileri yüklenemedi: $e");
    }
  }

  String _formatDuration(int seconds) {
    if (seconds.isNaN || seconds < 0) return '00:00';
    Duration duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _playlistDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Veri bulunamadı."));
          }

          final List<Track> tracks = snapshot.data!['tracks'];
          final Map<String, dynamic>? creatorData = snapshot.data!['creator'];

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(creatorData),
              _buildTrackListSliver(tracks),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(Map<String, dynamic>? creatorData) {
    final creatorName = creatorData?['username'] ?? 'Bilinmeyen Kullanıcı';

    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      floating: false,
      elevation: 2,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
        title: Text(widget.playlist.name,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 2, color: Colors.black87)])),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.playlist.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.playlist.imageUrl,
                    fit: BoxFit.cover,
                  )
                : Container(color: Colors.grey),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PublicProfileScreen(
                          userId: widget.playlist.creatorId),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Oluşturan: ',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          shadows: const [
                            Shadow(blurRadius: 1, color: Colors.black)
                          ]),
                    ),
                    Text(
                      creatorName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        shadows: const [
                          Shadow(blurRadius: 1, color: Colors.black)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackListSliver(List<Track> tracks) {
    final audioPlayerService =
        Provider.of<AudioPlayerService>(context, listen: false);

    if (tracks.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Center(
            child: Text('Bu çalma listesinde hiç şarkı yok.'),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = tracks[index];
          return TrackTile(
            track: track,
            formattedDuration: _formatDuration(track.duration),
            onTap: () {
              audioPlayerService.setPlaylist(tracks, index);
              audioPlayerService.playTrack(track);
            },
          );
        },
        childCount: tracks.length,
      ),
    );
  }
}
