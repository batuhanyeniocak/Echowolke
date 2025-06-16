import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_app/screens/edit_profile_screen.dart'; // Bu import'u kendi projenize göre güncelleyin
import '../services/firebase_service.dart'; // Bu import'u kendi projenize göre güncelleyin
import '../models/track.dart'; // Bu import'u kendi projenize göre güncelleyin
import '../widgets/track_tile.dart'; // Bu import'u kendi projenize göre güncelleyin
import '../services/audio_player_service.dart'; // Bu import'u kendi projenize göre güncelleyin
import '../models/playlist.dart'; // Bu import'u kendi projenize göre güncelleyin
import 'playlist_detail_screen.dart'; // Bu import'u kendi projenize göre güncelleyin

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  final User? _user = FirebaseAuth.instance.currentUser;

  // Veri yükleme state'leri kaldırıldı, artık StreamBuilder yönetecek.

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Ana widget StreamBuilder ile sarmalandı.
      body: _user == null
          ? const Center(child: Text('Profili görüntülemek için giriş yapın.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data?.data() == null) {
                  return const Center(child: Text("Kullanıcı bulunamadı."));
                }

                // Anlık olarak gelen veri snapshot'tan alınır.
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
    );
  }

  // Metot artık anlık veriyi parametre olarak alıyor.
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
              // HATA DÜZELTMESİ: Bu satır, backgroundImage null olduğunda
              // hataya neden olduğu için kaldırıldı.
              // onBackgroundImageError: (_, __) {},
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
                        stream: _firebaseService.getLikedSongs(_user!.uid),
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
                        stream: _firebaseService.getUserPlaylists(_user!.uid),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Profili Düzenle'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.share_outlined)),
                  ],
                ),
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
      tabs: const [
        Tab(text: 'Beğenilenler'),
        Tab(text: 'Listeler'),
      ],
    );
  }

  Widget _buildLikedTrackList() {
    if (_user == null) return const SizedBox.shrink();

    return StreamBuilder<List<Track>>(
      stream: _firebaseService.getLikedSongs(_user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Henüz hiç şarkı beğenilmemiş.',
              style: TextStyle(color: Colors.grey),
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

  Widget _buildPlaylistList() {
    if (_user == null) return const SizedBox.shrink();

    return StreamBuilder<List<Playlist>>(
      stream: _firebaseService.getUserPlaylists(_user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final playlists = snapshot.data ?? [];

        if (playlists.isEmpty) {
          return const Center(
            child: Text(
              'Henüz bir çalma listeniz yok.',
              style: TextStyle(color: Colors.grey),
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
                              width: 60, height: 60, color: Colors.grey[300]),
                          errorWidget: (context, url, error) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[400],
                              child: const Icon(Icons.broken_image, size: 30)),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[400],
                          child: const Icon(Icons.music_note,
                              size: 30, color: Colors.white70),
                        ),
                ),
                title: Text(playlist.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${playlist.trackIds.length} şarkı',
                    style: TextStyle(color: Colors.grey[600])),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          PlaylistDetailScreen(playlist: playlist),
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
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
