// lib/models/track.dart
class Track {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;
  final int duration;
  final int playCount;
  bool isPlaying;
  bool isLiked;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
    required this.duration,
    required this.playCount,
    this.isPlaying = false,
    this.isLiked = false,
  });
}
