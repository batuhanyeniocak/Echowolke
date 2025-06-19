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
  State<PublicPlaylistDetailScreen> createState() =>
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _playlistDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary)));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("Hata: ${snapshot.error}",
                    style: textTheme.bodyLarge
                        ?.copyWith(color: colorScheme.error)));
          }
          if (!snapshot.hasData) {
            return Center(
                child: Text("Veri bulunamadı.",
                    style: textTheme.bodyLarge
                        ?.copyWith(color: colorScheme.onBackground)));
          }

          final List<Track> tracks = snapshot.data!['tracks'];
          final Map<String, dynamic>? creatorData = snapshot.data!['creator'];

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(creatorData, colorScheme, textTheme),
              _buildTrackListSliver(tracks, colorScheme, textTheme),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(Map<String, dynamic>? creatorData,
      ColorScheme colorScheme, TextTheme textTheme) {
    final creatorName = creatorData?['username'] ?? 'Bilinmeyen Kullanıcı';
    final creatorProfileImageUrl = creatorData?['profileImageUrl'];

    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      floating: false,
      elevation: 2,
      backgroundColor: colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.playlist.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.playlist.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surface.withOpacity(0.5),
                      child: Center(
                          child: Icon(Icons.music_note,
                              size: 80,
                              color: colorScheme.onSurface.withOpacity(0.7))),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colorScheme.surface.withOpacity(0.7),
                      child: Center(
                          child: Icon(Icons.broken_image,
                              size: 80,
                              color: colorScheme.onSurface.withOpacity(0.7))),
                    ),
                  )
                : Container(color: colorScheme.surface.withOpacity(0.7)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.background.withOpacity(0.6),
                    Colors.transparent,
                    colorScheme.background.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.playlist.name,
                    style: textTheme.headlineSmall?.copyWith(
                        fontSize: 28,
                        color: colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                              blurRadius: 2,
                              color: colorScheme.onBackground.withOpacity(0.5))
                        ]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      if (creatorData != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PublicProfileScreen(
                                userId: widget.playlist.creatorId),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: colorScheme.surface.withOpacity(0.5),
                          backgroundImage: (creatorProfileImageUrl != null &&
                                  creatorProfileImageUrl.isNotEmpty)
                              ? CachedNetworkImageProvider(
                                      creatorProfileImageUrl)
                                  as ImageProvider<Object>
                              : null,
                          child: (creatorProfileImageUrl == null ||
                                  creatorProfileImageUrl.isEmpty)
                              ? Icon(Icons.person,
                                  size: 16,
                                  color: colorScheme.onSurface.withOpacity(0.7))
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          creatorName,
                          style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onBackground,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: colorScheme.onBackground,
                              shadows: [
                                Shadow(
                                    blurRadius: 1,
                                    color: colorScheme.onBackground
                                        .withOpacity(0.5))
                              ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.playlist.description ?? 'Açıklama yok',
                    style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.8)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.playlist.trackIds.length} şarkı',
                    style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackListSliver(
      List<Track> tracks, ColorScheme colorScheme, TextTheme textTheme) {
    final audioPlayerService =
        Provider.of<AudioPlayerService>(context, listen: false);

    if (tracks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Center(
            child: Text('Bu çalma listesinde hiç şarkı yok.',
                style: textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onBackground)),
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
