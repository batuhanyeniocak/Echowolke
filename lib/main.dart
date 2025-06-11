import 'package:flutter/material.dart';
import 'package:flutter_app/data/tracks_data.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/library_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/services/firebase_service.dart';
import 'package:flutter_app/screens/auth_screen.dart';

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

  runApp(
    Provider<FirebaseService>(
      create: (context) => FirebaseService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
            print('Kullanıcı giriş yaptı: ${snapshot.data!.email}');
            return const MainScreen();
          }
          print('Kullanıcı giriş yapmadı.');
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

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
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
    );
  }
}
