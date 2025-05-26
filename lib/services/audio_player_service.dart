// lib/services/audio_player_service.dart
import 'dart:async';
import 'package:flutter_app/models/track.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Track? _currentTrack;
  // Playlist için yeni alanlar
  List<Track> _playlist = [];
  int _currentIndex = -1;

  // Track değişimini dinlemek için stream
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

  // Playlist ayarlama fonksiyonu
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

      // Track playlistte mi kontrol et
      final index = _playlist.indexWhere((t) => t.id == track.id);
      if (index != -1) {
        _currentIndex = index;
      } else {
        // Eğer track playlistte değilse, playlistin boş olup olmadığını kontrol et
        if (_playlist.isEmpty) {
          // Playlist boşsa, yeni şarkıyı ekle
          _playlist.add(track);
          _currentIndex = 0;
        } else {
          // Playlistte şarkı var ama bu şarkı playlistte değil
          _playlist.add(track);
          _currentIndex = _playlist.length - 1;
        }
      }

      _currentTrack = track;

      // Track değiştiğinde stream'e bildir
      _currentTrackStreamController.add(track);

      await _audioPlayer.stop();
      await _audioPlayer.setUrl(track.audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      print('Şarkı çalma hatası: $e');
    }
  }

  // Sonraki şarkıya geçme fonksiyonu
  Future<void> playNextTrack() async {
    if (_playlist.isEmpty || _currentIndex < 0) {
      return;
    }

    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      await playTrack(_playlist[_currentIndex]);
    } else {
      // Playlistin sonuna geldik, başa dönebiliriz (döngüsel çalma)
      _currentIndex = 0;
      await playTrack(_playlist[_currentIndex]);
    }
  }

  // Önceki şarkıya geçme fonksiyonu
  Future<void> playPreviousTrack() async {
    if (_playlist.isEmpty || _currentIndex < 0) {
      return;
    }

    // Eğer şarkı 3 saniyeden fazla çalındıysa, başa sar
    if (_audioPlayer.position.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } else {
      // Değilse, önceki şarkıya geç
      if (_currentIndex > 0) {
        _currentIndex--;
        await playTrack(_playlist[_currentIndex]);
      } else {
        // İlk şarkıda olduğumuzda son şarkıya git (döngüsel)
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
