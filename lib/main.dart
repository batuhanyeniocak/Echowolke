import 'package:flutter/material.dart';
import 'package:flutter_app/data/tracks_data.dart';
import 'package:flutter_app/models/track.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';
import 'screens/liked_songs_screen.dart';
import 'screens/add_song_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/services/firebase_service.dart';
import 'package:flutter_app/screens/auth_screen.dart';
import 'package:flutter_app/services/audio_player_service.dart';
import 'package:flutter_app/widgets/player_mini.dart';
import 'package:rxdart/rxdart.dart';
import 'screens/playlists_screen.dart';
import 'screens/create_playlist_screen.dart';
import 'screens/playlist_detail_screen.dart';
import 'models/playlist.dart';
import 'package:flutter_app/theme/app_theme.dart';
import 'package:flutter_app/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await TracksData.loadTracks();
  } catch (e) {
    print("TracksData yüklenirken hata: $e");
  }

  final firebaseService = FirebaseService();
  final audioPlayerService = AudioPlayerService();
  audioPlayerService.setFirebaseService(firebaseService);
  await audioPlayerService.init();

  runApp(
    Provider<FirebaseService>(
      create: (context) => firebaseService,
      child: Provider<AudioPlayerService>(
        create: (context) => audioPlayerService,
        dispose: (context, service) => service.dispose(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echowolke',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainAppRouter extends StatelessWidget {
  const MainAppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }
        return const AuthScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
  ];

  Future<bool> _onWillPop() async {
    final NavigatorState? currentNavigator =
        _navigatorKeys[_selectedIndex].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerService = Provider.of<AudioPlayerService>(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        await _onWillPop();
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens.asMap().entries.map((entry) {
                  int index = entry.key;
                  Widget screen = entry.value;
                  return Navigator(
                    key: _navigatorKeys[index],
                    onGenerateRoute: (settings) {
                      if (settings.name == '/') {
                        return MaterialPageRoute(builder: (context) => screen);
                      }
                      if (settings.name == '/playlists') {
                        return MaterialPageRoute(
                            builder: (context) => const PlaylistsScreen());
                      }
                      if (settings.name == '/createPlaylist') {
                        return MaterialPageRoute(
                            builder: (context) => const CreatePlaylistScreen());
                      }
                      if (settings.name == '/playlistDetail') {
                        final args = settings.arguments as Playlist;
                        return MaterialPageRoute(
                            builder: (context) =>
                                PlaylistDetailScreen(playlist: args));
                      }
                      if (settings.name == '/likedSongs') {
                        return MaterialPageRoute(
                            builder: (context) => const LikedSongsScreen());
                      }
                      if (settings.name == '/addSong') {
                        return MaterialPageRoute(
                            builder: (context) => const AddSongScreen());
                      }
                      return MaterialPageRoute(builder: (context) => screen);
                    },
                  );
                }).toList(),
              ),
            ),
            StreamBuilder<Tuple2<Track?, bool>>(
              stream: Rx.combineLatest2(
                audioPlayerService.currentTrackStream,
                audioPlayerService.isPlayingStream,
                (Track? track, bool isPlaying) => Tuple2(track, isPlaying),
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.item1 == null) {
                  return const SizedBox.shrink();
                }

                final currentTrack = snapshot.data!.item1!;
                final isPlaying = snapshot.data!.item2;

                return PlayerMini(
                  track: currentTrack,
                  isPlaying: isPlaying,
                  onPlayPause: () {
                    if (isPlaying) {
                      audioPlayerService.pauseTrack();
                    } else {
                      audioPlayerService.playTrack(currentTrack);
                    }
                  },
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (_selectedIndex == index) {
              _navigatorKeys[index]
                  .currentState
                  ?.popUntil((route) => route.isFirst);
            }
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Keşfet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music),
              label: 'Kütüphane',
            ),
          ],
        ),
      ),
    );
  }
}

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  Tuple2(this.item1, this.item2);
}
