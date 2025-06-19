import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

import '../services/firebase_service.dart';
import '../services/audio_player_service.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../widgets/track_tile.dart';
import 'public_profile_screen.dart';
import 'public_playlist_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Track> _trackResults = [];
  List<Map<String, dynamic>> _userResults = [];
  List<Playlist> _playlistResults = [];

  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        if (!mounted) return;
        setState(() {
          _hasSearched = false;
          _trackResults = [];
          _userResults = [];
          _playlistResults = [];
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    final trackFuture = firebaseService.searchTracks(query);
    final userFuture = firebaseService.searchUsers(query);
    final playlistFuture = firebaseService.searchPlaylists(query);

    final results =
        await Future.wait([trackFuture, userFuture, playlistFuture]);

    if (!mounted) return;
    setState(() {
      _trackResults = results[0] as List<Track>;
      _userResults = results[1] as List<Map<String, dynamic>>;
      _playlistResults = results[2] as List<Playlist>;
      _isLoading = false;
    });
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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Keşfet',
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                style:
                    textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Şarkı, sanatçı veya çalma listesi ara',
                  hintStyle: textTheme.bodyLarge
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                  prefixIcon: Icon(Icons.search,
                      color: colorScheme.onSurface.withOpacity(0.8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            TabBar(
              tabs: const [
                Tab(text: 'Parçalar'),
                Tab(text: 'Profiller'),
                Tab(text: 'Listeler'),
              ],
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: colorScheme.primary,
              labelStyle:
                  textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              unselectedLabelStyle: textTheme.labelLarge,
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary)))
                  : !_hasSearched
                      ? Center(
                          child: Text(
                            'Aramak için yazmaya başlayın.',
                            style: textTheme.bodyLarge
                                ?.copyWith(color: colorScheme.onBackground),
                          ),
                        )
                      : TabBarView(
                          children: [
                            _buildResultsList(_trackResults, context),
                            _buildResultsList(_userResults, context),
                            _buildResultsList(_playlistResults, context),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(List<dynamic> results, BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (results.isEmpty) {
      return Center(
          child: Text(
        'Sonuç bulunamadı.',
        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onBackground),
      ));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];

        if (item is Track) {
          return TrackTile(
            track: item,
            formattedDuration: _formatDuration(item.duration),
            onTap: () {
              Provider.of<AudioPlayerService>(context, listen: false)
                ..setPlaylist(results.cast<Track>(), index)
                ..playTrack(item);
            },
          );
        }

        if (item is Map<String, dynamic>) {
          return ListTile(
            tileColor: colorScheme.background,
            leading: CircleAvatar(
              backgroundColor: colorScheme.surface.withOpacity(0.5),
              backgroundImage: item['profileImageUrl'] != null &&
                      item['profileImageUrl'].isNotEmpty
                  ? CachedNetworkImageProvider(item['profileImageUrl'])
                  : null,
              child: item['profileImageUrl'] == null ||
                      item['profileImageUrl'].isEmpty
                  ? Icon(Icons.person,
                      color: colorScheme.onSurface.withOpacity(0.8))
                  : null,
            ),
            title: Text(
              item['username'] ?? 'Bilinmeyen Kullanıcı',
              style:
                  textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => PublicProfileScreen(userId: item['uid']),
              ));
            },
          );
        }
        if (item is Playlist) {
          return ListTile(
            tileColor: colorScheme.background,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover)
                  : Container(
                      width: 50,
                      height: 50,
                      color: colorScheme.surface.withOpacity(0.7),
                      child:
                          Icon(Icons.music_note, color: colorScheme.onSurface)),
            ),
            title: Text(
              item.name,
              style:
                  textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
            ),
            subtitle: Text(
              '${item.trackIds.length} şarkı',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    PublicPlaylistDetailScreen(playlist: item),
              ));
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
