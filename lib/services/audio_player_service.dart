import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/track.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_app/services/firebase_service.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();

  factory AudioPlayerService() {
    return _instance;
  }

  AudioPlayerService._internal();

  final AudioPlayer audioPlayer = AudioPlayer();
  List<Track> currentPlaylist = [];
  int currentTrackIndex = -1;
  Track? _currentTrack;
  final BehaviorSubject<Track?> _currentTrackSubject =
      BehaviorSubject<Track?>();
  FirebaseService? _firebaseService;

  Stream<Track?> get currentTrackStream => _currentTrackSubject.stream;
  Track? get currentTrack => _currentTrack;
  bool get isPlaying => audioPlayer.playing;

  void setFirebaseService(FirebaseService service) {
    _firebaseService = service;
  }

  Future<void> init() async {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );
    audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        playNextTrack();
      }
    });
  }

  void setPlaylist(List<Track> playlist, int initialIndex) {
    currentPlaylist = playlist;
    currentTrackIndex = initialIndex;
  }

  Future<void> playTrack(Track track) async {
    if (_currentTrack?.id == track.id && audioPlayer.playing) {
      await audioPlayer.pause();
    } else if (_currentTrack?.id == track.id && !audioPlayer.playing) {
      await audioPlayer.play();
    } else {
      _currentTrack = track;
      _currentTrackSubject.add(track);
      await audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(track.audioUrl),
          tag: MediaItem(
            id: track.id,
            album: track.artist,
            title: track.title,
            artUri: Uri.parse(track.coverUrl),
          ),
        ),
      );
      await audioPlayer.play();
      _firebaseService?.incrementTrackPlayCount(track.id);
    }
  }

  Future<void> pauseTrack() async {
    await audioPlayer.pause();
  }

  Future<void> playNextTrack() async {
    if (currentPlaylist.isEmpty) return;
    if (audioPlayer.loopMode == LoopMode.one) {
      audioPlayer.seek(Duration.zero);
      audioPlayer.play();
      return;
    }

    int nextIndex = currentTrackIndex + 1;
    if (audioPlayer.shuffleModeEnabled) {
      await audioPlayer.setShuffleModeEnabled(true);
      await audioPlayer.shuffle();
      nextIndex = (audioPlayer.currentIndex ?? 0);
    } else {
      nextIndex = (currentTrackIndex + 1) % currentPlaylist.length;
    }

    if (nextIndex < currentPlaylist.length) {
      currentTrackIndex = nextIndex;
      await playTrack(currentPlaylist[currentTrackIndex]);
    } else if (audioPlayer.loopMode == LoopMode.all) {
      currentTrackIndex = 0;
      await playTrack(currentPlaylist[currentTrackIndex]);
    } else {
      await audioPlayer.stop();
      _currentTrack = null;
      _currentTrackSubject.add(null);
    }
  }

  Future<void> playPreviousTrack() async {
    if (currentPlaylist.isEmpty) return;
    if (audioPlayer.position.inSeconds > 3) {
      audioPlayer.seek(Duration.zero);
      return;
    }

    int prevIndex = currentTrackIndex - 1;
    if (prevIndex >= 0) {
      currentTrackIndex = prevIndex;
      await playTrack(currentPlaylist[currentTrackIndex]);
    } else if (audioPlayer.loopMode == LoopMode.all) {
      currentTrackIndex = currentPlaylist.length - 1;
      await playTrack(currentPlaylist[currentTrackIndex]);
    } else {
      await audioPlayer.stop();
      _currentTrack = null;
      _currentTrackSubject.add(null);
    }
  }
}
