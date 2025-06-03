import 'dart:async';
import 'package:flutter_app/models/track.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Track? _currentTrack;

  List<Track> _playlist = [];
  int _currentIndex = -1;

  final StreamController<Track> _currentTrackStreamController =
      StreamController<Track>.broadcast();

  static final AudioPlayerService _instance = AudioPlayerService._internal();

  factory AudioPlayerService() {
    return _instance;
  }

  AudioPlayerService._internal();

  AudioPlayer get audioPlayer => _audioPlayer;
  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _audioPlayer.playing;
  List<Track> get currentPlaylist => _playlist;
  int get currentIndex => _currentIndex;
  Stream<Track> get currentTrackStream => _currentTrackStreamController.stream;

  void setPlaylist(List<Track> tracks, int startIndex) {
    _playlist = List.from(tracks);
    _currentIndex = startIndex.clamp(0, _playlist.length - 1);
  }

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

      final index = _playlist.indexWhere((t) => t.id == track.id);
      if (index != -1) {
        _currentIndex = index;
      } else {
        if (_playlist.isEmpty) {
          _playlist.add(track);
          _currentIndex = 0;
        } else {
          _playlist.add(track);
          _currentIndex = _playlist.length - 1;
        }
      }

      _currentTrack = track;

      _currentTrackStreamController.add(track);

      await _audioPlayer.stop();
      await _audioPlayer.setUrl(track.audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      print('Şarkı çalma hatası: $e');
    }
  }

  Future<void> playNextTrack() async {
    if (_playlist.isEmpty || _currentIndex < 0) {
      return;
    }

    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      await playTrack(_playlist[_currentIndex]);
    } else {
      _currentIndex = 0;
      await playTrack(_playlist[_currentIndex]);
    }
  }

  Future<void> playPreviousTrack() async {
    if (_playlist.isEmpty || _currentIndex < 0) {
      return;
    }

    if (_audioPlayer.position.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } else {
      if (_currentIndex > 0) {
        _currentIndex--;
        await playTrack(_playlist[_currentIndex]);
      } else {
        _currentIndex = _playlist.length - 1;
        await playTrack(_playlist[_currentIndex]);
      }
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
    _currentTrackStreamController.close();
  }
}
