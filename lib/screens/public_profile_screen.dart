import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/firebase_service.dart';
import '../models/track.dart';
import '../widgets/track_tile.dart';
import '../services/audio_player_service.dart';
import '../models/playlist.dart';
import 'playlist_detail_screen.dart';
import 'edit_profile_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({required this.userId, super.key});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  late final bool _isOwnProfile;

  @override
  void initState() {
    super.initState();
    _isOwnProfile = FirebaseAuth.instance.currentUser?.uid == widget.userId;
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text("Kullanıcı bulunamadı."));
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
                    delegate: _SliverTabBarDelegate(_buildTabBar()),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _buildLikedTrackList(),
                  _buildPlaylistList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 70.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic> userData) {
    final username = userData['username'] ?? 'Kullanıcı';
    final profileImageUrl = userData['profileImageUrl'] ?? '';

    return Column(
      children: [
        Transform.translate(
          offset: const Offset(0, -50),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: CircleAvatar(
              radius: 46,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? CachedNetworkImageProvider(profileImageUrl)
                  : null,
              backgroundColor: Colors.grey[200],
              child: profileImageUrl.isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
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
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Track>>(
                        stream: _firebaseService.getLikedSongs(widget.userId),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData
                              ? snapshot.data!.length.toString()
                              : '0';
                          return _buildStatColumn('Beğenilenler', count);
                        },
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<Playlist>>(
                        stream:
                            _firebaseService.getUserPlaylists(widget.userId),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData
                              ? snapshot.data!.length.toString()
                              : '0';
                          return _buildStatColumn('Listeler', count);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isOwnProfile)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Profili Düzenle'),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {/* Takip etme mantığı buraya eklenebilir */},
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: const Text("Takip Et"),
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
      ],
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      labelColor: Theme.of(context).primaryColor,
      unselectedLabelColor: Colors.grey[600],
      indicatorColor: Theme.of(context).primaryColor,
      tabs: const [Tab(text: 'Beğenilenler'), Tab(text: 'Listeler')],
    );
  }

  Widget _buildLikedTrackList() {
    return StreamBuilder<List<Track>>(
      stream: _firebaseService.getLikedSongs(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Beğenilen şarkı yok.'));
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

  Widget _buildPlaylistList() {
    return StreamBuilder<List<Playlist>>(
      stream: _firebaseService.getUserPlaylists(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Çalma listesi yok.'));
        }
        final playlists = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                title: Text(playlist.name),
                subtitle: Text('${playlist.trackIds.length} şarkı'),
                leading: playlist.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: CachedNetworkImage(
                            imageUrl: playlist.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey,
                        child:
                            const Icon(Icons.music_note, color: Colors.white)),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        PlaylistDetailScreen(playlist: playlist))),
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
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
