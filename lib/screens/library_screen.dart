import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_app/services/firebase_service.dart';
import 'add_song_screen.dart';
import 'liked_songs_screen.dart';
import 'playlists_screen.dart';
import 'profile_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String? _username;
  String? _profileImageUrl;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (mounted && userDoc.exists) {
        setState(() {
          _username = userDoc.data()?['username'];
          _profileImageUrl = userDoc.data()?['profileImageUrl'];
        });
      }
    } catch (e) {
      print("Kullanıcı verisi yüklenemedi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kütüphane'),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildProfileTile(context),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Beğendiklerim'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToPage(context, const LikedSongsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: const Text('Çalma Listelerim'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToPage(context, const PlaylistsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.library_add),
            title: const Text('Şarkı Ekle'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToPage(context, const AddSongScreen()),
          ),
          const Divider(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await firebaseService.signOut();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Başarıyla çıkış yapıldı.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Çıkış yapılırken hata oluştu: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context) {
    final displayName = _username ?? "Profil";
    final imageUrl = _profileImageUrl;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      onTap: () => _navigateToPage(context, const ProfileScreen()),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
            ? CachedNetworkImageProvider(imageUrl)
            : null,
        child: (imageUrl == null || imageUrl.isEmpty)
            ? const Icon(Icons.person, size: 30, color: Colors.white)
            : null,
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: const Text('Profili görüntüle'),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}
