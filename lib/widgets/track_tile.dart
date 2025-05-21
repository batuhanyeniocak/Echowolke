import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../screens/player_screen.dart'; // PlayerScreen'i import edin

class TrackTile extends StatefulWidget {
  final Track track;

  const TrackTile({Key? key, required this.track}) : super(key: key);

  @override
  State<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Şarkı çalma durumunu dinleme
    _audioPlayerService.audioPlayer.playerStateStream.listen((playerState) {
      final isCurrentTrackPlaying =
          _audioPlayerService.currentTrack?.id == widget.track.id &&
              playerState.playing;

      if (mounted && isPlaying != isCurrentTrackPlaying) {
        setState(() {
          isPlaying = isCurrentTrackPlaying;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: Image.network(
          widget.track.coverUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 50,
              height: 50,
              color: Colors.grey,
              child: const Icon(Icons.music_note, color: Colors.white),
            );
          },
        ),
      ),
      title: Text(widget.track.title),
      subtitle: Text(widget.track.artist),
      trailing: IconButton(
        icon: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: isPlaying ? Theme.of(context).primaryColor : null,
        ),
        onPressed: () {
          _audioPlayerService.playTrack(widget.track);
        },
      ),
      onTap: () {
        _audioPlayerService.playTrack(widget.track);
      },
      onLongPress: () {
        // Uzun basınca PlayerScreen'e yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(track: widget.track),
          ),
        );
      },
    );
  }
}
