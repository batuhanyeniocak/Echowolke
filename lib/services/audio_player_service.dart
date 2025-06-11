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

  late StreamSubscription _playerStateSubscription;

  factory AudioPlayerService() {
    return _instance;
  }

  AudioPlayerService._internal() {
    _initAudioPlayerListeners();
  }

  void _initAudioPlayerListeners() {
    _playerStateSubscription =
        _audioPlayer.playerStateStream.listen((playerState) {
      print(
          "[AudioPlayerService Listener] Durum değişti: ${playerState.processingState}");
      if (playerState.processingState == ProcessingState.completed) {
        print(
            "[AudioPlayerService Listener] Şarkı bitti: ${_currentTrack?.title ?? 'Bilinmeyen Şarkı'}");
        playNextTrack();
      }
    });
  }

  AudioPlayer get audioPlayer => _audioPlayer;
  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _audioPlayer.playing;
  List<Track> get currentPlaylist => _playlist;
  int get currentIndex => _currentIndex;
  Stream<Track> get currentTrackStream => _currentTrackStreamController.stream;

  void setPlaylist(List<Track> tracks, int startIndex) {
    _playlist = List.from(tracks);
    _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    print(
        "[AudioPlayerService] Oynatma listesi ayarlandı. Toplam şarkı: ${_playlist.length}, Başlangıç indeksi: $startIndex");
  }

  Future<void> playTrack(Track track) async {
    try {
      if (_currentTrack?.id == track.id) {
        if (_audioPlayer.playing) {
          print("[playTrack] Aynı şarkı ($_currentTrack) duraklatılıyor.");
          await _audioPlayer.pause();
        } else {
          print(
              "[playTrack] Aynı şarkı ($_currentTrack) çalmaya devam ediliyor.");
          await _audioPlayer.play();
        }
        return;
      }

      print("[playTrack] Yeni şarkı çalınıyor: ${track.title}");

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
        print(
            "[playTrack] Şarkı oynatma listesine eklendi. Yeni indeks: $_currentIndex");
      }

      _currentTrack = track;
      _currentTrackStreamController.add(track);

      print("[playTrack] Player URL ayarlanıyor: ${track.audioUrl}");
      await _audioPlayer.setUrl(track.audioUrl);
      print("[playTrack] Player çalmaya başlıyor.");
      await _audioPlayer.play();
      print("[playTrack] Şarkı çalmaya başladı: ${track.title}");
    } catch (e) {
      print('[playTrack] Şarkı çalma hatası: $e');
    }
  }

  Future<void> playNextTrack() async {
    print("[playNextTrack] Fonksiyon çağrıldı.");
    if (_playlist.isEmpty || _currentIndex < 0) {
      print(
          "[playNextTrack] Sonraki şarkıya geçilemiyor: Oynatma listesi boş veya indeks geçersiz. Playlist: ${_playlist.length}, Current Index: $_currentIndex");
      return;
    }

    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      print(
          "[playNextTrack] Sonraki şarkıya geçiliyor: Yeni indeks $_currentIndex, Şarkı: ${_playlist[_currentIndex].title}");
      await playTrack(_playlist[_currentIndex]);
    } else {
      _currentIndex = 0;
      print(
          "[playNextTrack] Oynatma listesi sonu, başa dönülüyor: Yeni indeks $_currentIndex, Şarkı: ${_playlist[_currentIndex].title}");
      await playTrack(_playlist[_currentIndex]);
    }
  }

  Future<void> playPreviousTrack() async {
    print("[playPreviousTrack] Fonksiyon çağrıldı.");
    if (_playlist.isEmpty || _currentIndex < 0) {
      print(
          "[playPreviousTrack] Önceki şarkıya geçilemiyor: Oynatma listesi boş veya indeks geçersiz. Playlist: ${_playlist.length}, Current Index: $_currentIndex");
      return;
    }

    if (_audioPlayer.position.inSeconds > 5) {
      print("[playPreviousTrack] Şarkı başa sarılıyor.");
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } else {
      if (_currentIndex > 0) {
        _currentIndex--;
        print(
            "[playPreviousTrack] Önceki şarkıya geçiliyor: Yeni indeks $_currentIndex, Şarkı: ${_playlist[_currentIndex].title}");
        await playTrack(_playlist[_currentIndex]);
      } else {
        _currentIndex = _playlist.length - 1;
        print(
            "[playPreviousTrack] Oynatma listesi başı, sona dönülüyor: Yeni indeks $_currentIndex, Şarkı: ${_playlist[_currentIndex].title}");
        await playTrack(_playlist[_currentIndex]);
      }
    }
  }

  Future<void> pauseTrack() async {
    print("[pauseTrack] Şarkı duraklatıldı.");
    await _audioPlayer.pause();
  }

  Future<void> stopTrack() async {
    print("[stopTrack] Şarkı durduruldu ve sıfırlandı.");
    await _audioPlayer.stop();
    _currentTrack = null;
    _currentIndex = -1;
    _currentTrackStreamController.addError('No track playing');
  }

  void dispose() {
    print("[AudioPlayerService] dispose ediliyor.");
    _playerStateSubscription.cancel();
    _audioPlayer.dispose();
    _currentTrackStreamController.close();
  }
}
