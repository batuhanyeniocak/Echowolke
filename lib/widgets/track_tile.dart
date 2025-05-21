import 'package:flutter/material.dart';
import '../models/track.dart';
import '../screens/player_screen.dart';

class TrackTile extends StatelessWidget {
  final Track track;

  const TrackTile({Key? key, required this.track}) : super(key: key);

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(
            image: NetworkImage(track.coverUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        track.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(track.artist),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_formatDuration(track.duration)),
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(
              track.isLiked ? Icons.favorite : Icons.favorite_border,
              color: track.isLiked ? Colors.red : null,
              size: 20,
            ),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {},
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'playlist',
                child: Text('Çalma listesine ekle'),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Text('Paylaş'),
              ),
              const PopupMenuItem(
                value: 'download',
                child: Text('İndir'),
              ),
            ],
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(track: track),
          ),
        );
      },
    );
  }
}
