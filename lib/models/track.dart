class Track {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;
  final int duration;
  final int playCount;
  final bool isLiked;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
    required this.duration,
    this.playCount = 0,
    this.isLiked = false,
  });
}
