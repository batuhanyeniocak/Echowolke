import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../services/firebase_service.dart';
import '../services/audio_player_service.dart';
import 'create_playlist_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late Future<List<Track>> _tracksFuture;
  late Playlist _currentPlaylist;

  @override
  void initState() {
    super.initState();
    _currentPlaylist = widget.playlist;
    _loadTracks();
  }

  void _loadTracks() {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    _tracksFuture = firebaseService.getTracksByIds(_currentPlaylist.trackIds);
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
      setState(() {
        for (var track in selectedTracks) {
          if (!_currentPlaylist.trackIds.contains(track.id)) {
            _currentPlaylist.trackIds.add(track.id);
          }
        }
        _loadTracks();
      });

      for (var track in selectedTracks) {
        await firebaseService.addTrackToPlaylist(_currentPlaylist.id, track.id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${selectedTracks.length} şarkı çalma listesine eklendi!')),
      );
    }
  }

  void _removeTrackFromPlaylist(String trackId) async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    try {
      await firebaseService.removeTrackFromPlaylist(
          _currentPlaylist.id, trackId);
      setState(() {
        _currentPlaylist.trackIds.remove(trackId);
        _loadTracks();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şarkı çalma listesinden çıkarıldı.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Şarkı çıkarılırken hata: $e'),
            backgroundColor: Colors.red),
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
          setState(() {
            _currentPlaylist = updatedPlaylist;
            _loadTracks();
          });
        }
      });
    });
  }

  void _deletePlaylist() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çalma Listesini Sil'),
        content: const Text(
            'Bu çalma listesini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await firebaseService.deletePlaylist(_currentPlaylist.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çalma listesi başarıyla silindi.')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Silme hatası: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showTrackOptions(Track track) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final firebaseService = Provider.of<FirebaseService>(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(track.title),
                subtitle: Text(track.artist),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: StreamBuilder<bool>(
                  stream: firebaseService.isTrackLikedStream(track.id),
                  builder: (context, snapshot) {
                    final isLiked = snapshot.data ?? false;
                    return Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : null,
                    );
                  },
                ),
                title: StreamBuilder<bool>(
                  stream: firebaseService.isTrackLikedStream(track.id),
                  builder: (context, snapshot) {
                    final isLiked = snapshot.data ?? false;
                    return Text(isLiked ? 'Beğenmekten Vazgeç' : 'Beğen');
                  },
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final isLiked = await firebaseService.isTrackLiked(track.id);
                  await firebaseService.toggleLikedSong(track.id, !isLiked);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isLiked
                            ? 'Şarkı beğenilenlerden kaldırıldı.'
                            : 'Şarkı beğenilenlere eklendi!',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.remove_circle_outline, color: Colors.red),
                title: const Text('Çalma Listesinden Çıkar'),
                onTap: () {
                  Navigator.pop(context);
                  _removeTrackFromPlaylist(track.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlaylistOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Çalma Listesini Düzenle'),
                onTap: () {
                  Navigator.pop(context);
                  _editPlaylist();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Çalma Listesini Sil'),
                onTap: () {
                  Navigator.pop(context);
                  _deletePlaylist();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerService =
        Provider.of<AudioPlayerService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çalma Listesi Detayı'),
        backgroundColor: Colors.orange,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
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
                            color: Colors.grey[300],
                            child: const Icon(Icons.music_note,
                                size: 50, color: Colors.white70),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[400],
                            child: const Icon(Icons.broken_image,
                                size: 50, color: Colors.white70),
                          ),
                        )
                      : Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[400],
                          child: const Icon(Icons.music_note,
                              size: 50, color: Colors.white70),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentPlaylist.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _currentPlaylist.description ?? 'Açıklama yok',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_currentPlaylist.trackIds.length} şarkı',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _addSongsToPlaylist,
                        icon: const Icon(Icons.add),
                        label: const Text('Şarkı Ekle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Track>>(
              future: _tracksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child:
                          Text('Şarkılar yüklenirken hata: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Bu çalma listesinde henüz şarkı yok.'));
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
                            color: Colors.grey[300],
                            child: const Icon(Icons.music_note,
                                size: 25, color: Colors.white70),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[400],
                            child: const Icon(Icons.broken_image,
                                size: 25, color: Colors.white70),
                          ),
                        ),
                      ),
                      title: Text(track.title),
                      subtitle: Text(track.artist),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Çalma Listesine Şarkı Ekle',
            style: Theme.of(context).textTheme.headlineSmall,
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
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CachedNetworkImage(
                    imageUrl: track.coverUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note,
                          size: 25, color: Colors.white70),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[400],
                      child: const Icon(Icons.broken_image,
                          size: 25, color: Colors.white70),
                    ),
                  ),
                ),
                title: Text(track.title),
                subtitle: Text(track.artist),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.radio_button_unchecked),
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTracks.remove(track);
                    } else {
                      _selectedTracks.add(track);
                    }
                  });
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
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Seçilenleri Ekle (${_selectedTracks.length})'),
          ),
        ),
      ],
    );
  }
}
