import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';

class PlayerScreen extends StatefulWidget {
  final Track track;

  const PlayerScreen({Key? key, required this.track}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isPlaying = false;
  double _currentPosition = 0;

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: NetworkImage(widget.track.coverUrl),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  widget.track.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  widget.track.artist,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Slider(
                  value: _currentPosition,
                  max: widget.track.duration.toDouble(),
                  onChanged: (value) {
                    setState(() {
                      _currentPosition = value;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_currentPosition.toInt())),
                      Text(_formatDuration(widget.track.duration)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 35),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 70,
                        color: Colors.orange,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPlaying = !_isPlaying;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 35),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.repeat),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        widget.track.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.track.isLiked ? Colors.red : null,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.playlist_add),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//butonlar simdilik aktif degil..
