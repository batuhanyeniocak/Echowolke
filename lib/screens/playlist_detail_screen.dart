import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../services/firebase_service.dart';
import '../services/audio_player_service.dart';
import 'create_playlist_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'public_profile_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late Future<List<Track>> _tracksFuture;
  late Playlist _currentPlaylist;
  String? _creatorUsername;
  String? _creatorProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _currentPlaylist = widget.playlist;
    _loadTracks();
    _loadCreatorData();
  }

  void _loadTracks() {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    _tracksFuture = firebaseService.getTracksByIds(_currentPlaylist.trackIds);
  }

  void _loadCreatorData() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final creatorDoc =
        await firebaseService.getUserData(_currentPlaylist.creatorId);
    if (creatorDoc != null && mounted) {
      setState(() {
        _creatorUsername = creatorDoc['username'];
        _creatorProfileImageUrl = creatorDoc['profileImageUrl'];
      });
    }
  }

  void _addSongsToPlaylist() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final allTracks = await firebaseService.getAllTracksOnce();

    final currentTrackIds = _currentPlaylist.trackIds.toSet();
    final availableTracks = allTracks
        .where((track) => !currentTrackIds.contains(track.id))
        .toList();

    if (!mounted) return;

    final List<Track>? selectedTracks = await showModalBottomSheet<List<Track>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return AddSongsToPlaylistSheet(
              tracks: availableTracks,
              scrollController: controller,
            );
          },
        );
      },
    );

    if (selectedTracks != null && selectedTracks.isNotEmpty) {
      if (mounted) {
        setState(() {
          for (var track in selectedTracks) {
            if (!_currentPlaylist.trackIds.contains(track.id)) {
              _currentPlaylist.trackIds.add(track.id);
            }
          }
          _loadTracks();
        });
      }

      for (var track in selectedTracks) {
        await firebaseService.addTrackToPlaylist(_currentPlaylist.id, track.id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${selectedTracks.length} şarkı çalma listesine eklendi!'),
            backgroundColor: Theme.of(context).colorScheme.onBackground),
      );
    }
  }

  void _removeTrackFromPlaylist(String trackId) async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    try {
      await firebaseService.removeTrackFromPlaylist(
          _currentPlaylist.id, trackId);
      if (mounted) {
        setState(() {
          _currentPlaylist.trackIds.remove(trackId);
          _loadTracks();
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Şarkı çalma listesinden çıkarıldı.'),
            backgroundColor: Theme.of(context).colorScheme.onBackground),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Şarkı çıkarılırken hata: $e'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  void _editPlaylist() {
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) =>
            CreatePlaylistScreen(playlistToEdit: _currentPlaylist),
        transitionDuration: Duration.zero,
        transitionsBuilder: (context, animation1, animation2, child) {
          return child;
        },
      ),
    )
        .then((_) {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      firebaseService
          .getPlaylistById(_currentPlaylist.id)
          .then((updatedPlaylist) {
        if (updatedPlaylist != null) {
          if (mounted) {
            setState(() {
              _currentPlaylist = updatedPlaylist;
              _loadTracks();
            });
          }
        }
      });
    });
  }

  void _deletePlaylist() async {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Çalma Listesini Sil',
            style:
                textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        content: Text(
            'Bu çalma listesini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
            style: textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            child: Text('İptal',
                style:
                    textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: Text('Sil',
                style:
                    textTheme.labelLarge?.copyWith(color: colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final firebaseService =
            Provider.of<FirebaseService>(context, listen: false);
        await firebaseService.deletePlaylist(_currentPlaylist.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Çalma listesi başarıyla silindi.'),
              backgroundColor: Theme.of(context).colorScheme.onBackground),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Silme hatası: $e'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  void _showPlaylistOptions() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Container(
            color: colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit,
                      color: colorScheme.onSurface.withOpacity(0.8)),
                  title: Text('Çalma Listesini Düzenle',
                      style: textTheme.titleMedium
                          ?.copyWith(color: colorScheme.onSurface)),
                  onTap: () {
                    Navigator.pop(context);
                    _editPlaylist();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: colorScheme.error),
                  title: Text('Çalma Listesini Sil',
                      style: textTheme.titleMedium
                          ?.copyWith(color: colorScheme.onSurface)),
                  onTap: () {
                    Navigator.pop(context);
                    _deletePlaylist();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTrackOptions(Track track) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final firebaseService = Provider.of<FirebaseService>(context);
        final ColorScheme colorScheme = Theme.of(context).colorScheme;
        final TextTheme textTheme = Theme.of(context).textTheme;

        return SafeArea(
          child: Container(
            color: colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline,
                      color: colorScheme.onSurface.withOpacity(0.8)),
                  title: Text(track.title,
                      style: textTheme.titleMedium
                          ?.copyWith(color: colorScheme.onSurface)),
                  subtitle: Text(track.artist,
                      style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7))),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Divider(color: colorScheme.onSurface.withOpacity(0.1)),
                ListTile(
                  leading: StreamBuilder<bool>(
                    stream: firebaseService.isTrackLikedStream(track.id),
                    builder: (context, snapshot) {
                      final isLiked = snapshot.data ?? false;
                      return Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked
                            ? colorScheme.primary
                            : colorScheme.onSurface.withOpacity(0.8),
                      );
                    },
                  ),
                  title: StreamBuilder<bool>(
                    stream: firebaseService.isTrackLikedStream(track.id),
                    builder: (context, snapshot) {
                      final isLiked = snapshot.data ?? false;
                      return Text(isLiked ? 'Beğenmekten Vazgeç' : 'Beğen',
                          style: textTheme.titleMedium
                              ?.copyWith(color: colorScheme.onSurface));
                    },
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final isLiked =
                        await firebaseService.isTrackLiked(track.id);
                    await firebaseService.toggleLikedSong(track.id, !isLiked);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isLiked
                              ? 'Şarkı beğenilenlerden kaldırıldı.'
                              : 'Şarkı beğenilenlere eklendi!',
                        ),
                        backgroundColor:
                            Theme.of(context).colorScheme.onBackground,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.remove_circle_outline,
                      color: colorScheme.error),
                  title: Text('Çalma Listesinden Çıkar',
                      style: textTheme.titleMedium
                          ?.copyWith(color: colorScheme.onSurface)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeTrackFromPlaylist(track.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerService =
        Provider.of<AudioPlayerService>(context, listen: false);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Çalma Listesi Detayı',
            style:
                textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            onPressed: _showPlaylistOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _currentPlaylist.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _currentPlaylist.imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 120,
                            height: 120,
                            color: colorScheme.surface.withOpacity(0.5),
                            child: Icon(Icons.music_note,
                                size: 50,
                                color: colorScheme.onSurface.withOpacity(0.7)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 120,
                            height: 120,
                            color: colorScheme.surface.withOpacity(0.7),
                            child: Icon(Icons.broken_image,
                                size: 50,
                                color: colorScheme.onSurface.withOpacity(0.7)),
                          ),
                        )
                      : Container(
                          width: 120,
                          height: 120,
                          color: colorScheme.surface.withOpacity(0.7),
                          child: Icon(Icons.music_note,
                              size: 50,
                              color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentPlaylist.name,
                        style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onBackground,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _currentPlaylist.description ?? 'Açıklama yok',
                        style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 5),
                      if (_creatorUsername != null)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => PublicProfileScreen(
                                  userId: _currentPlaylist.creatorId),
                            ));
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor:
                                    colorScheme.surface.withOpacity(0.5),
                                backgroundImage:
                                    (_creatorProfileImageUrl != null &&
                                            _creatorProfileImageUrl!.isNotEmpty)
                                        ? CachedNetworkImageProvider(
                                                _creatorProfileImageUrl!)
                                            as ImageProvider<Object>
                                        : null,
                                child: (_creatorProfileImageUrl == null ||
                                        _creatorProfileImageUrl!.isEmpty)
                                    ? Icon(Icons.person,
                                        size: 12,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7))
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _creatorUsername!,
                                style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onBackground
                                        .withOpacity(0.7),
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 5),
                      Text(
                        '${_currentPlaylist.trackIds.length} şarkı',
                        style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _addSongsToPlaylist,
                        icon: Icon(Icons.add, color: colorScheme.onPrimary),
                        label: Text('Şarkı Ekle', style: textTheme.labelLarge),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: colorScheme.onSurface.withOpacity(0.1)),
          Expanded(
            child: FutureBuilder<List<Track>>(
              future: _tracksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary)));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          'Şarkılar yüklenirken hata: ${snapshot.error}',
                          style: textTheme.bodyLarge
                              ?.copyWith(color: colorScheme.error)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text('Bu çalma listesinde henüz şarkı yok.',
                          style: textTheme.bodyLarge
                              ?.copyWith(color: colorScheme.onBackground)));
                }

                final tracks = snapshot.data!;
                return ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: CachedNetworkImage(
                          imageUrl: track.coverUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surface.withOpacity(0.5),
                            child: Icon(Icons.music_note,
                                size: 25,
                                color: colorScheme.onSurface.withOpacity(0.7)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surface.withOpacity(0.7),
                            child: Icon(Icons.broken_image,
                                size: 25,
                                color: colorScheme.onSurface.withOpacity(0.7)),
                          ),
                        ),
                      ),
                      title: Text(track.title,
                          style: textTheme.titleMedium
                              ?.copyWith(color: colorScheme.onSurface)),
                      subtitle: Text(track.artist,
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7))),
                      trailing: IconButton(
                        icon: Icon(Icons.more_vert,
                            color: colorScheme.onSurface.withOpacity(0.8)),
                        onPressed: () => _showTrackOptions(track),
                      ),
                      onTap: () {
                        audioPlayerService.setPlaylist(tracks, index);
                        audioPlayerService.playTrack(track);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddSongsToPlaylistSheet extends StatefulWidget {
  final List<Track> tracks;
  final ScrollController scrollController;

  const AddSongsToPlaylistSheet({
    super.key,
    required this.tracks,
    required this.scrollController,
  });

  @override
  State<AddSongsToPlaylistSheet> createState() =>
      _AddSongsToPlaylistSheetState();
}

class _AddSongsToPlaylistSheetState extends State<AddSongsToPlaylistSheet> {
  final List<Track> _selectedTracks = [];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Çalma Listesine Şarkı Ekle',
            style:
                textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: widget.tracks.length,
            itemBuilder: (context, index) {
              final track = widget.tracks[index];
              final isSelected = _selectedTracks.contains(track);
              return ListTile(
                tileColor: isSelected
                    ? colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CachedNetworkImage(
                    imageUrl: track.coverUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surface.withOpacity(0.5),
                      child: Icon(Icons.music_note,
                          size: 25,
                          color: colorScheme.onSurface.withOpacity(0.7)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colorScheme.surface.withOpacity(0.7),
                      child: Icon(Icons.broken_image,
                          size: 25,
                          color: colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  ),
                ),
                title: Text(track.title,
                    style: textTheme.titleMedium
                        ?.copyWith(color: colorScheme.onSurface)),
                subtitle: Text(track.artist,
                    style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7))),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : Icon(Icons.radio_button_unchecked,
                        color: colorScheme.onSurface.withOpacity(0.6)),
                onTap: () {
                  if (mounted) {
                    setState(() {
                      if (isSelected) {
                        _selectedTracks.remove(track);
                      } else {
                        _selectedTracks.add(track);
                      }
                    });
                  }
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(_selectedTracks);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Seçilenleri Ekle (${_selectedTracks.length})',
                style: textTheme.labelLarge),
          ),
        ),
      ],
    );
  }
}
