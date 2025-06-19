import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_app/screens/edit_profile_screen.dart';
import '../services/firebase_service.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';
import '../services/audio_player_service.dart';
import '../models/playlist.dart';
import 'playlist_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  final User? _user = FirebaseAuth.instance.currentUser;

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
      backgroundColor: colorScheme.background,
      body: _user == null
          ? Center(
              child: Text('Profili görüntülemek için giriş yapın.',
                  style: textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onBackground)))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary)));
                }
                if (!snapshot.hasData || snapshot.data?.data() == null) {
                  return Center(
                      child: Text("Kullanıcı bulunamadı.",
                          style: textTheme.bodyLarge
                              ?.copyWith(color: colorScheme.onBackground)));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;

                return DefaultTabController(
                  length: 2,
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        _buildSliverAppBar(),
                        SliverToBoxAdapter(child: _buildProfileInfo(userData)),
                        SliverPersistentHeader(
                          delegate: _SliverTabBarDelegate(
                              _buildTabBar(colorScheme, textTheme)),
                          pinned: true,
                        ),
                      ];
                    },
                    body: TabBarView(
                      children: [
                        _buildLikedTrackList(colorScheme, textTheme),
                        _buildPlaylistList(colorScheme, textTheme),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      expandedHeight: 70.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: colorScheme.onBackground),
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic> userData) {
    final username = userData['username'] ?? 'Kullanıcı';
    final profileImageUrl = userData['profileImageUrl'] ?? '';
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Transform.translate(
          offset: const Offset(0, -50),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: colorScheme.background,
            child: CircleAvatar(
              radius: 46,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? CachedNetworkImageProvider(profileImageUrl)
                  : null,
              backgroundColor: colorScheme.surface.withOpacity(0.5),
              child: profileImageUrl.isEmpty
                  ? Icon(Icons.person,
                      size: 50, color: colorScheme.onSurface.withOpacity(0.7))
                  : null,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text(username,
                    style: textTheme.headlineSmall?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Track>>(
                        stream: _firebaseService.getLikedSongs(_user!.uid),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData
                              ? snapshot.data!.length.toString()
                              : '0';
                          return _buildStatColumn(
                              'Beğenilenler', count, colorScheme, textTheme);
                        },
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<Playlist>>(
                        stream: _firebaseService.getUserPlaylists(_user!.uid),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData
                              ? snapshot.data!.length.toString()
                              : '0';
                          return _buildStatColumn(
                              'Listeler', count, colorScheme, textTheme);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.edit,
                          size: 18, color: colorScheme.onPrimary),
                      label:
                          Text('Profili Düzenle', style: textTheme.labelLarge),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, ColorScheme colorScheme,
      TextTheme textTheme) {
    return Column(
      children: [
        Text(value,
            style: textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground)),
        const SizedBox(height: 4),
        Text(label,
            style: textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: colorScheme.onBackground.withOpacity(0.7))),
      ],
    );
  }

  TabBar _buildTabBar(ColorScheme colorScheme, TextTheme textTheme) {
    return TabBar(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
      indicatorColor: colorScheme.primary,
      labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: textTheme.labelLarge,
      tabs: const [
        Tab(text: 'Beğenilenler'),
        Tab(text: 'Listeler'),
      ],
    );
  }

  Widget _buildLikedTrackList(ColorScheme colorScheme, TextTheme textTheme) {
    if (_user == null) return const SizedBox.shrink();

    return StreamBuilder<List<Track>>(
      stream: _firebaseService.getLikedSongs(_user!.uid),
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
                  style:
                      textTheme.bodyLarge?.copyWith(color: colorScheme.error)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Henüz hiç şarkı beğenilmemiş.',
              style: textTheme.bodyLarge
                  ?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
            ),
          );
        }

        final likedTracks = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.zero,
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
    );
  }

  Widget _buildPlaylistList(ColorScheme colorScheme, TextTheme textTheme) {
    if (_user == null) return const SizedBox.shrink();

    return StreamBuilder<List<Playlist>>(
      stream: _firebaseService.getUserPlaylists(_user!.uid),
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
                  style:
                      textTheme.bodyLarge?.copyWith(color: colorScheme.error)));
        }

        final playlists = snapshot.data ?? [];

        if (playlists.isEmpty) {
          return Center(
            child: Text(
              'Henüz bir çalma listeniz yok.',
              style: textTheme.bodyLarge
                  ?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 2,
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: playlist.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: playlist.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 60,
                            height: 60,
                            color: colorScheme.surface.withOpacity(0.5),
                            child: Icon(Icons.music_note,
                                size: 30,
                                color: colorScheme.onSurface.withOpacity(0.7)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: colorScheme.surface.withOpacity(0.7),
                            child: Icon(Icons.broken_image,
                                size: 30,
                                color: colorScheme.onSurface.withOpacity(0.7)),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: colorScheme.surface.withOpacity(0.7),
                          child: Icon(Icons.music_note,
                              size: 30,
                              color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                ),
                title: Text(playlist.name,
                    style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface)),
                subtitle: Text('${playlist.trackIds.length} şarkı',
                    style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7))),
                trailing: Icon(Icons.chevron_right,
                    color: colorScheme.onSurface.withOpacity(0.6)),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          PlaylistDetailScreen(playlist: playlist),
                      transitionDuration: Duration.zero,
                      transitionsBuilder:
                          (context, animation1, animation2, child) {
                        return child;
                      },
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
