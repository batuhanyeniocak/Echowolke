import 'dart:async';
import 'package:flutter_app/models/track.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Track? _currentTrack;

  List<Track> _playlist = [];
  int _currentIndex = -1;

  final StreamController<Track?> _currentTrackStreamController =
      StreamController<Track?>.broadcast();

  static final AudioPlayerService _instance = AudioPlayerService._internal();

  late StreamSubscription _playerStateSubscription;

  factory AudioPlayerService() {
    return _instance;
  }

  // Özel kurucu metodunda ses çalıcı dinleyicilerini başlatır
  AudioPlayerService._internal() {
    _initAudioPlayerListeners();
  }

  // AudioPlayer'ın durum değişikliklerini dinler
  void _initAudioPlayerListeners() {
    _playerStateSubscription =
        _audioPlayer.playerStateStream.listen((playerState) {
      // Şarkı çalma tamamlandığında sonraki şarkıya geç
      if (playerState.processingState == ProcessingState.completed) {
        print("Şarkı bitti, sonraki şarkıya geçiliyor...");
        playNextTrack();
      }
    }, onError: (e) {
      print("Audio player stream hatası: $e");
    });
  }

  // Genel erişim sağlayan getter'lar
  AudioPlayer get audioPlayer => _audioPlayer;
  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _audioPlayer.playing;
  List<Track> get currentPlaylist => _playlist;
  int get currentIndex => _currentIndex;
  Stream<Track?> get currentTrackStream => _currentTrackStreamController.stream;

  // Oynatma listesini ayarlar
  void setPlaylist(List<Track> tracks, int startIndex) {
    _playlist = List.from(tracks);
    _currentIndex = startIndex.clamp(0, _playlist.length - 1);
    print(
        "Oynatma listesi ayarlandı: Toplam şarkı: ${_playlist.length}, Başlangıç indeksi: $startIndex");
  }

  // Bir şarkıyı çalar veya mevcut şarkıyı duraklatıp devam ettirir
  Future<void> playTrack(Track track) async {
    try {
      // Eğer tıklanan şarkı zaten çalıyorsa veya duraklatılmışsa (ID'leri aynıysa)
      if (_currentTrack?.id == track.id) {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
          print("Aynı şarkı: Duraklatıldı.");
        } else {
          await _audioPlayer.play();
          print("Aynı şarkı: Çalmaya devam edildi.");
        }
        return; // İşlemi burada sonlandır
      }

      // Yeni bir şarkı çalınıyorsa
      print("Yeni şarkı çalınıyor: ${track.title}");

      // Şarkının oynatma listesindeki indeksini bul
      final index = _playlist.indexWhere((t) => t.id == track.id);
      if (index != -1) {
        _currentIndex = index;
      } else {
        // Şarkı listede yoksa, listeye ekle ve indeksi ayarla
        if (_playlist.isEmpty) {
          _playlist.add(track);
          _currentIndex = 0;
        } else {
          _playlist.add(track);
          _currentIndex = _playlist.length - 1;
        }
        print("Şarkı oynatma listesine eklendi. Yeni indeks: $_currentIndex");
      }

      _currentTrack = track; // Güncel şarkıyı ayarla
      _currentTrackStreamController
          .add(track); // Çalınan şarkıyı dinleyicilere bildir

      // just_audio ile URL'yi ayarla ve oynat
      await _audioPlayer.setUrl(track.audioUrl);
      await _audioPlayer.play();
      print("Şarkı çalmaya başladı: ${track.title}");
    } catch (e) {
      print('Şarkı çalma hatası: $e');
      // Hata durumunda kullanıcıya bildirim gönderebilirsiniz
    }
  }

  // Sonraki şarkıya geçişi sağlar
  Future<void> playNextTrack() async {
    if (_playlist.isEmpty || _currentIndex == -1) {
      print(
          "Sonraki şarkıya geçilemiyor: Oynatma listesi boş veya indeks geçersiz.");
      return;
    }

    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      print(
          "Sonraki şarkıya geçiliyor: Yeni indeks $_currentIndex, Şarkı: ${_playlist[_currentIndex].title}");
      await playTrack(_playlist[_currentIndex]);
    } else {
      // Oynatma listesinin sonuna gelindiyse başa dön (döngüsel oynatma)
      _currentIndex = 0;
      print(
          "Oynatma listesi sonu, başa dönülüyor: Yeni indeks $_currentIndex, Şarkı: ${_playlist[_currentIndex].title}");
      await playTrack(_playlist[_currentIndex]);
    }
  }

  // Önceki şarkıya geçişi sağlar
  Future<void> playPreviousTrack() async {
    if (_playlist.isEmpty || _currentIndex == -1) {
      print(
          "Önceki şarkıya geçilemiyor: Oynatma listesi boş veya indeks geçersiz.");
      return;
    }

    // Eğer şarkının başında değilsen (ilk 3 saniye içinde değilse), başa sar
    if (_audioPlayer.position.inSeconds > 3) {
      print("Şarkı başa sarılıyor.");
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } else {
      // Değilse, önceki şarkıya geç
      if (_currentIndex > 0) {
        _currentIndex--;
        print(
            "Önceki şarkıya geçiliyor: Yeni indeks $_currentIndex, Şarkı: ${_playlist[_currentIndex].title}");
        await playTrack(_playlist[_currentIndex]);
      } else {
        // Oynatma listesinin başındaysan, sona dön (döngüsel oynatma)
        _currentIndex = _playlist.length - 1;
        print(
            "Oynatma listesi başı, sona dönülüyor: Yeni indeks $_currentIndex, Şarkı: ${_playlist[_currentIndex].title}");
        await playTrack(_playlist[_currentIndex]);
      }
    }
  }

  // Şarkıyı duraklatır
  Future<void> pauseTrack() async {
    print("Şarkı duraklatıldı.");
    await _audioPlayer.pause();
  }

  // Şarkıyı durdurur ve çalıcıyı sıfırlar
  Future<void> stopTrack() async {
    print("Şarkı durduruldu ve sıfırlandı.");
    await _audioPlayer.stop();
    _currentTrack = null;
    _currentIndex = -1;
    _currentTrackStreamController.add(null); // Çalınan şarkı olmadığını bildir
  }

  // Kaynakları serbest bırakır
  void dispose() {
    print("AudioPlayerService dispose ediliyor.");
    _playerStateSubscription.cancel(); // Dinleyiciyi iptal et
    _audioPlayer.dispose();
    _currentTrackStreamController.close();
  }
}
