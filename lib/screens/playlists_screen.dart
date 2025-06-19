import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Çalma Listelerim',
              style:
                  textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
          backgroundColor: colorScheme.surface,
          elevation: 0,
        ),
        body: Center(
          child: Text('Çalma listelerinizi görmek için giriş yapmalısınız.',
              style: textTheme.bodyLarge
                  ?.copyWith(color: colorScheme.onBackground)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Çalma Listelerim',
            style:
                textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: colorScheme.onSurface),
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
                child: Text(
              'Henüz bir çalma listeniz yok. Yeni bir tane oluşturun!',
              style: textTheme.bodyLarge
                  ?.copyWith(color: colorScheme.onBackground),
            ));
          }

          final playlists = snapshot.data!;

          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
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
                                  color:
                                      colorScheme.onSurface.withOpacity(0.7)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 60,
                              height: 60,
                              color: colorScheme.surface.withOpacity(0.7),
                              child: Icon(Icons.broken_image,
                                  size: 30,
                                  color:
                                      colorScheme.onSurface.withOpacity(0.7)),
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
                  title: Text(
                    playlist.name,
                    style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    '${playlist.trackIds.length} şarkı',
                    style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
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
      ),
    );
  }
}
