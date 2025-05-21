import 'dart:async';
import '../models/track.dart';

class AudioService {
  Track? _currentTrack;
  bool _isPlaying = false;
  final StreamController<double> _positionController =
      StreamController<double>.broadcast();
  final StreamController<Track?> _currentTrackController =
      StreamController<Track?>.broadcast();
  final StreamController<bool> _playStateController =
      StreamController<bool>.broadcast();

  // Singleton pattern
  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal();

  // Getters
  Stream<double> get positionStream => _positionController.stream;
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;
  Stream<bool> get playStateStream => _playStateController.stream;
  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;

  // Metodlar
  Future<void> play(Track track) async {
    _currentTrack = track;
    _isPlaying = true;
    _currentTrackController.add(track);
    _playStateController.add(true);

    // Simüle edilmiş oynatma ilerlemesi
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }

      // Simüle edilmiş pozisyon güncellemesi
      // Gerçek uygulamada burada ses çalar kütüphanesi kullanılacak
    });
  }

  void pause() {
    if (_isPlaying) {
      _isPlaying = false;
      _playStateController.add(false);
    }
  }

  void resume() {
    if (!_isPlaying && _currentTrack != null) {
      _isPlaying = true;
      _playStateController.add(true);
    }
  }

  void stop() {
    _isPlaying = false;
    _playStateController.add(false);
  }

  void seekTo(double position) {
    if (_currentTrack != null) {
      _positionController.add(position);
    }
  }

  void dispose() {
    _positionController.close();
    _currentTrackController.close();
    _playStateController.close();
  }
}
