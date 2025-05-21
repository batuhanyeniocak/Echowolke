import 'package:flutter_app/models/track.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Track? _currentTrack;

  static final AudioPlayerService _instance = AudioPlayerService._internal();

  factory AudioPlayerService() {
    return _instance;
  }

  AudioPlayerService._internal();

  AudioPlayer get audioPlayer => _audioPlayer;
  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _audioPlayer.playing;

  Future<void> playTrack(Track track) async {
    try {
      if (_currentTrack?.id == track.id) {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
        return;
      }

      _currentTrack = track;
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(track.audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      print('Şarkı çalma hatası: $e');
    }
  }

  Future<void> pauseTrack() async {
    await _audioPlayer.pause();
  }

  Future<void> stopTrack() async {
    await _audioPlayer.stop();
    _currentTrack = null;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
