import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/playlist.dart';
import 'create_playlist_screen.dart';
import 'playlist_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Çalma Listelerim'),
          backgroundColor: Colors.orange,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Çalma listelerinizi görmek için giriş yapmalısınız.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çalma Listelerim'),
        backgroundColor: Colors.orange,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                      const CreatePlaylistScreen(),
                  transitionDuration: Duration.zero,
                  transitionsBuilder: (context, animation1, animation2, child) {
                    return child;
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Playlist>>(
        stream: firebaseService.getUserPlaylists(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
                    'Henüz bir çalma listeniz yok. Yeni bir tane oluşturun!'));
          }

          final playlists = snapshot.data!;

          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
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
                              color: Colors.grey[300],
                              child: const Icon(Icons.music_note,
                                  size: 30, color: Colors.white70),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[400],
                              child: const Icon(Icons.broken_image,
                                  size: 30, color: Colors.white70),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[400],
                            child: const Icon(Icons.music_note,
                                size: 30, color: Colors.white70),
                          ),
                  ),
                  title: Text(
                    playlist.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${playlist.trackIds.length} şarkı',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.chevron_right),
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
      ),
    );
  }
}
