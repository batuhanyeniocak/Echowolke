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

  runApp(
    Provider<FirebaseService>(
      create: (context) => firebaseService,
      child: Provider<AudioPlayerService>(
        create: (context) => audioPlayerService,
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
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Roboto',
      ),
      home: StreamBuilder<User?>(
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
      ),
      debugShowCheckedModeBanner: false,
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
            StreamBuilder<Track?>(
              stream: audioPlayerService.currentTrackStream,
              builder: (context, snapshot) {
                final currentTrack = snapshot.data;
                if (currentTrack == null) {
                  return const SizedBox.shrink();
                }
                final isPlaying = audioPlayerService.isPlaying;

                return PlayerMini(
                  track: currentTrack,
                  isPlaying: isPlaying,
                  onPlayPause: () {
                    if (audioPlayerService.isPlaying) {
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
