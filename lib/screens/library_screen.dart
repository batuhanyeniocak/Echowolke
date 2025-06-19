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
import 'edit_profile_screen.dart';
import 'package:flutter_app/main.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Kütüphane',
              style:
                  textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
          backgroundColor: colorScheme.surface,
          elevation: 0,
        ),
        body: Center(
          child: Text('İçeriği görmek için lütfen giriş yapın.',
              style: textTheme.bodyLarge
                  ?.copyWith(color: colorScheme.onBackground)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Center(
                child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            )),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final username = userData?['username'];
        final profileImageUrl = userData?['profileImageUrl'];

        return Scaffold(
          appBar: AppBar(
            title: Text('Kütüphane',
                style: textTheme.titleLarge
                    ?.copyWith(color: colorScheme.onSurface)),
            backgroundColor: colorScheme.surface,
            elevation: 0,
          ),
          body: ListView(
            children: [
              _buildProfileTile(context, username, profileImageUrl),
              Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.1)),
              ListTile(
                leading: Icon(Icons.edit_outlined,
                    color: colorScheme.onSurface.withOpacity(0.8)),
                title: Text('Profili Düzenle',
                    style: textTheme.titleMedium
                        ?.copyWith(color: colorScheme.onSurface)),
                trailing: Icon(Icons.chevron_right,
                    color: colorScheme.onSurface.withOpacity(0.6)),
                onTap: () =>
                    _navigateToPage(context, const EditProfileScreen()),
              ),
              ListTile(
                leading: Icon(Icons.favorite_border,
                    color: colorScheme.onSurface.withOpacity(0.8)),
                title: Text('Beğendiklerim',
                    style: textTheme.titleMedium
                        ?.copyWith(color: colorScheme.onSurface)),
                trailing: Icon(Icons.chevron_right,
                    color: colorScheme.onSurface.withOpacity(0.6)),
                onTap: () => _navigateToPage(context, const LikedSongsScreen()),
              ),
              ListTile(
                leading: Icon(Icons.playlist_play_outlined,
                    color: colorScheme.onSurface.withOpacity(0.8)),
                title: Text('Çalma Listelerim',
                    style: textTheme.titleMedium
                        ?.copyWith(color: colorScheme.onSurface)),
                trailing: Icon(Icons.chevron_right,
                    color: colorScheme.onSurface.withOpacity(0.6)),
                onTap: () => _navigateToPage(context, const PlaylistsScreen()),
              ),
              ListTile(
                leading: Icon(Icons.library_add_outlined,
                    color: colorScheme.onSurface.withOpacity(0.8)),
                title: Text('Şarkı Ekle',
                    style: textTheme.titleMedium
                        ?.copyWith(color: colorScheme.onSurface)),
                trailing: Icon(Icons.chevron_right,
                    color: colorScheme.onSurface.withOpacity(0.6)),
                onTap: () => _navigateToPage(context, const AddSongScreen()),
              ),
              ListTile(
                leading: Icon(
                  Theme.of(context).brightness == Brightness.light
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
                title: Text(
                  Theme.of(context).brightness == Brightness.light
                      ? 'Gece Moduna Geç'
                      : 'Gündüz Moduna Geç',
                  style: textTheme.titleMedium
                      ?.copyWith(color: colorScheme.onSurface),
                ),
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    themeNotifier.toggleTheme();
                  },
                  activeColor: colorScheme.primary,
                  inactiveThumbColor: colorScheme.onSurface.withOpacity(0.4),
                  inactiveTrackColor: colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
              Divider(color: colorScheme.onSurface.withOpacity(0.1)),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await firebaseService.signOut();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Başarıyla çıkış yapıldı.'),
                            backgroundColor: colorScheme.onBackground),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Çıkış yapılırken hata oluştu: $e'),
                            backgroundColor: colorScheme.error),
                      );
                    }
                  },
                  icon: Icon(Icons.logout, color: colorScheme.onError),
                  label: Text('Çıkış Yap', style: textTheme.labelLarge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
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
      },
    );
  }

  Widget _buildProfileTile(
      BuildContext context, String? username, String? imageUrl) {
    final displayName = username ?? "Profil";
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      onTap: () => _navigateToPage(context, const ProfileScreen()),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: colorScheme.surface.withOpacity(0.5),
        backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
            ? CachedNetworkImageProvider(imageUrl)
            : null,
        child: (imageUrl == null || imageUrl.isEmpty)
            ? Icon(Icons.person,
                size: 30, color: colorScheme.onSurface.withOpacity(0.7))
            : null,
      ),
      title: Text(
        displayName,
        style: textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface),
      ),
      subtitle: Text(
        'Profili görüntüle',
        style: textTheme.bodyMedium
            ?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
      ),
      trailing: Icon(Icons.chevron_right,
          color: colorScheme.onSurface.withOpacity(0.6)),
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
