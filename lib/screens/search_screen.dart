import 'package:flutter/material.dart';
import 'package:flutter_app/services/firebase_service.dart';
import 'package:flutter_app/models/track.dart';
import 'package:flutter_app/widgets/track_tile.dart';
import 'package:flutter_app/services/audio_player_service.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Track> _allTracks = [];
  List<Track> _searchResults = [];
  bool _isLoading = true;
  bool _hasSearched = false;
  FirebaseService? _firebaseService;
  AudioPlayerService? _audioPlayerService;

  StreamSubscription<List<Track>>? _tracksSubscription;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firebaseService = Provider.of<FirebaseService>(context, listen: false);
      _audioPlayerService =
          Provider.of<AudioPlayerService>(context, listen: false);
      _setupTracksListener();
    });

    _searchController.addListener(_onSearchChanged);
  }

  void _setupTracksListener() {
    _tracksSubscription = _firebaseService!.getAllTracks().listen((tracks) {
      setState(() {
        _allTracks = tracks;
        _isLoading = false;
      });
      _performSearch(_searchController.text);
    }, onError: (error) {
      print('Error fetching all tracks stream: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _hasSearched = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _hasSearched = true;
      _searchResults = _allTracks.where((track) {
        final lowerCaseQuery = query.toLowerCase();
        return track.title.toLowerCase().contains(lowerCaseQuery) ||
            track.artist.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    });
  }

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
      appBar: AppBar(
        title: const Text('Keşfet'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Şarkı, sanatçı veya albüm ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasSearched
                    ? _searchResults.isEmpty
                        ? Center(
                            child: Text(
                              'Sonuç bulunamadı.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final track = _searchResults[index];
                              return TrackTile(
                                track: track,
                                formattedDuration:
                                    _formatDuration(track.duration),
                                onTap: () {
                                  if (_audioPlayerService != null) {
                                    _audioPlayerService!
                                        .setPlaylist(_searchResults, index);
                                    _audioPlayerService!.playTrack(track);
                                  }
                                },
                              );
                            },
                          )
                    : Center(
                        child: Text(
                          'Bir şarkı aramaya başla',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tracksSubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
