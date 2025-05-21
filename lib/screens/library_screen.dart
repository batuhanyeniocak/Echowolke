import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kütüphane'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Beğendiklerim'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: const Text('Çalma Listelerim'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Geçmiş'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('İndirilenler'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// butonlar simdilik aktif degil :(
