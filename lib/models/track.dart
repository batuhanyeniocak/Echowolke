import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class Track {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;
  final int duration;
  final int playCount;
  final DateTime releaseDate;
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
    required this.releaseDate,
    this.isPlaying = false,
    this.isLiked = false,
  });

  factory Track.fromFirestore(Map<String, dynamic> data, String id) {
    return Track(
      id: id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      duration: data['duration'] ?? 0,
      playCount: data['playCount'] ?? 0,
      releaseDate: data['releaseDate'] != null
          ? (data['releaseDate'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'searchableTitle': title.toLowerCase(),
      'searchableArtist': artist.toLowerCase(),
      'coverUrl': coverUrl,
      'audioUrl': audioUrl,
      'duration': duration,
      'playCount': playCount,
      'releaseDate': Timestamp.fromDate(releaseDate),
    };
  }

  AudioSource toAudioSource() {
    return AudioSource.uri(
      Uri.parse(audioUrl),
      tag: MediaItem(
        id: id,
        title: title,
        artist: artist,
        artUri: Uri.parse(coverUrl),
        duration: Duration(seconds: duration),
      ),
    );
  }
}
