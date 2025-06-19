import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/firebase_service.dart';

class PlayerScreen extends StatefulWidget {
  final Track track;

  const PlayerScreen({Key? key, required this.track}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isDragging = false;
  bool _isLiked = false;
  bool _isShuffleEnabled = false;
  LoopMode _loopMode = LoopMode.off;
  double _currentVolume = 1.0;

  late Track _activeTrack;
  String? _currentUserId;

  late StreamSubscription _positionSubscription;
  late StreamSubscription _durationSubscription;
  late StreamSubscription _trackChangeSubscription;
  late StreamSubscription _playerStateSubscription;
  late StreamSubscription _authSubscription;
  late StreamSubscription _loopModeSubscription;
  late StreamSubscription _shuffleModeSubscription;
  late StreamSubscription _volumeSubscription;

  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _activeTrack = widget.track;
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _initializeAnimations();
    _initializePlayerState();
    _setupListeners();
    _checkLikedStatus();
    _initializePlaybackSettings();
  }

  void _initializeAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializePlayerState() async {
    if (_audioPlayerService.currentTrack?.id != widget.track.id) {
      await _audioPlayerService.playTrack(widget.track);
    }

    setState(() {
      _activeTrack = _audioPlayerService.currentTrack ?? widget.track;
      _isPlaying = _audioPlayerService.isPlaying;
      _currentPosition = _audioPlayerService.audioPlayer.position;
      _totalDuration =
          _audioPlayerService.audioPlayer.duration ?? Duration.zero;
      _currentVolume = _audioPlayerService.audioPlayer.volume;
    });

    _updateAnimations();
  }

  void _initializePlaybackSettings() {
    _loopMode = _audioPlayerService.audioPlayer.loopMode;
    _isShuffleEnabled = _audioPlayerService.audioPlayer.shuffleModeEnabled;
  }

  Future<void> _checkLikedStatus() async {
    if (_currentUserId != null) {
      final bool liked = await _firebaseService.isTrackLiked(_activeTrack.id);
      if (mounted) {
        setState(() {
          _isLiked = liked;
        });
      }
    }
  }

  Future<void> _toggleLikeStatus() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Şarkı beğenmek için giriş yapmalısınız.'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    try {
      if (_isLiked) {
        await _firebaseService.removeLikedSong(
            _currentUserId!, _activeTrack.id);
        if (mounted) {
          setState(() {
            _isLiked = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${_activeTrack.title} beğenilenlerden kaldırıldı.'),
              backgroundColor: Theme.of(context).colorScheme.onBackground),
        );
      } else {
        await _firebaseService.addLikedSong(_currentUserId!, _activeTrack);
        if (mounted) {
          setState(() {
            _isLiked = true;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${_activeTrack.title} beğenilenlere eklendi.'),
              backgroundColor: Theme.of(context).colorScheme.onBackground),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Beğenme durumu güncellenirken hata oluştu: $e'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  void _setupListeners() {
    _playerStateSubscription =
        _audioPlayerService.audioPlayer.playerStateStream.listen((playerState) {
      if (mounted) {
        _updatePlayingState();
      }
    });

    _positionSubscription =
        _audioPlayerService.audioPlayer.positionStream.listen((position) {
      if (mounted && !_isDragging) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _durationSubscription =
        _audioPlayerService.audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _trackChangeSubscription =
        _audioPlayerService.currentTrackStream.listen((track) {
      if (mounted && track != null) {
        setState(() {
          _activeTrack = track;
          _totalDuration = Duration(seconds: track.duration);
          _currentPosition = Duration.zero;
          _isPlaying = _audioPlayerService.isPlaying;
        });
        _updateAnimations();
        _checkLikedStatus();
      }
    });

    _authSubscription =
        _firebaseService.auth.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUserId = user?.uid;
        });
        _checkLikedStatus();
      }
    });

    _loopModeSubscription =
        _audioPlayerService.audioPlayer.loopModeStream.listen((loopMode) {
      if (mounted) {
        setState(() {
          _loopMode = loopMode;
        });
      }
    });

    _shuffleModeSubscription = _audioPlayerService
        .audioPlayer.shuffleModeEnabledStream
        .listen((shuffleEnabled) {
      if (mounted) {
        setState(() {
          _isShuffleEnabled = shuffleEnabled;
        });
      }
    });

    _volumeSubscription =
        _audioPlayerService.audioPlayer.volumeStream.listen((volume) {
      if (mounted) {
        setState(() {
          _currentVolume = volume;
        });
      }
    });
  }

  void _updatePlayingState() {
    final currentTrack = _audioPlayerService.currentTrack;
    final newIsPlaying = _audioPlayerService.isPlaying;

    if (mounted &&
        (_isPlaying != newIsPlaying || _activeTrack.id != currentTrack?.id)) {
      setState(() {
        _isPlaying = newIsPlaying;
        if (currentTrack != null) {
          _activeTrack = currentTrack;
        }
      });
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    if (_isPlaying) {
      _rotationController.repeat();
      _scaleController.reverse();
    } else {
      _rotationController.stop();
      _scaleController.forward();
    }
  }

  @override
  void dispose() {
    _playerStateSubscription.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _trackChangeSubscription.cancel();
    _authSubscription.cancel();
    _loopModeSubscription.cancel();
    _shuffleModeSubscription.cancel();
    _volumeSubscription.cancel();
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handlePlayPause() async {
    try {
      await _audioPlayerService.playTrack(_activeTrack);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _seekTo(Duration position) async {
    try {
      await _audioPlayerService.audioPlayer.seek(position);
    } catch (e) {
      print('Seek hatası: $e');
    }
  }

  Future<void> _toggleShuffle() async {
    final newShuffleState = !_isShuffleEnabled;
    await _audioPlayerService.audioPlayer
        .setShuffleModeEnabled(newShuffleState);
    if (mounted) {
      setState(() {
        _isShuffleEnabled = newShuffleState;
      });
    }
  }

  Future<void> _toggleRepeat() async {
    LoopMode newMode;
    if (_loopMode == LoopMode.off) {
      newMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      newMode = LoopMode.one;
    } else {
      newMode = LoopMode.off;
    }
    await _audioPlayerService.audioPlayer.setLoopMode(newMode);
    if (mounted) {
      setState(() {
        _loopMode = newMode;
      });
    }
  }

  Future<void> _setVolume(double volume) async {
    await _audioPlayerService.audioPlayer.setVolume(volume);
  }

  Widget _buildCoverArt() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight;
        final double availableWidth = constraints.maxWidth;
        final double maxSize = (availableHeight * 0.8).clamp(200.0, 280.0);
        final double actualSize =
            maxSize > availableWidth ? availableWidth * 0.8 : maxSize;

        final ColorScheme colorScheme = Theme.of(context).colorScheme;

        return Center(
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * 3.14159,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: actualSize,
                        height: actualSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 5,
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              spreadRadius: 10,
                              blurRadius: 30,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: _activeTrack.coverUrl,
                                width: actualSize,
                                height: actualSize,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: actualSize,
                                  height: actualSize,
                                  color: colorScheme.surface.withOpacity(0.5),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          colorScheme.primary),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return Container(
                                    width: actualSize,
                                    height: actualSize,
                                    color: colorScheme.surface.withOpacity(0.7),
                                    child: Icon(
                                      Icons.music_note,
                                      color: colorScheme.onSurface,
                                      size: actualSize * 0.3,
                                    ),
                                  );
                                },
                              ),
                              Container(
                                width: actualSize,
                                height: actualSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.1),
                                    ],
                                    stops: const [0.7, 1.0],
                                  ),
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: actualSize * 0.07,
                                  height: actualSize * 0.07,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: colorScheme.onBackground,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: _buildCoverArt(),
              ),
            ),
            Expanded(
              flex: 2,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double height = constraints.maxHeight;
                  final double buttonSize = height * 0.25;

                  return Container(
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Column(
                            children: [
                              Text(
                                _activeTrack.title,
                                style: textTheme.titleLarge?.copyWith(
                                  fontSize: height * 0.09,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: height * 0.015),
                              Text(
                                _activeTrack.artist,
                                style: textTheme.titleSmall?.copyWith(
                                  fontSize: height * 0.07,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.05),
                          Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: height * 0.025,
                                  ),
                                  overlayShape: RoundSliderOverlayShape(
                                    overlayRadius: height * 0.06,
                                  ),
                                ),
                                child: Slider(
                                  value: _currentPosition.inSeconds
                                      .toDouble()
                                      .clamp(0.0,
                                          _totalDuration.inSeconds.toDouble()),
                                  max: _totalDuration.inSeconds.toDouble(),
                                  activeColor: colorScheme.primary,
                                  inactiveColor:
                                      colorScheme.primary.withOpacity(0.3),
                                  onChangeStart: (value) => _isDragging = true,
                                  onChanged: (value) {
                                    setState(() {
                                      _currentPosition =
                                          Duration(seconds: value.toInt());
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    _isDragging = false;
                                    _seekTo(Duration(seconds: value.toInt()));
                                  },
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_currentPosition),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                        fontSize: height * 0.05,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_totalDuration),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                        fontSize: height * 0.05,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.05),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(Icons.skip_previous),
                                iconSize: buttonSize * 0.5,
                                color: colorScheme.onSurface,
                                onPressed: () async {
                                  await _audioPlayerService.playPreviousTrack();
                                },
                              ),
                              GestureDetector(
                                onTapDown: (_) => _scaleController.forward(),
                                onTapUp: (_) => _scaleController.reverse(),
                                onTapCancel: () => _scaleController.reverse(),
                                child: Container(
                                  width: buttonSize,
                                  height: buttonSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorScheme.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary
                                            .withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Icon(
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        key: ValueKey(_isPlaying),
                                        color: colorScheme.onPrimary,
                                        size: buttonSize * 0.5,
                                      ),
                                    ),
                                    onPressed: _handlePlayPause,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.skip_next),
                                iconSize: buttonSize * 0.5,
                                color: colorScheme.onSurface,
                                onPressed: () async {
                                  await _audioPlayerService.playNextTrack();
                                },
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(Icons.shuffle),
                                iconSize: height * 0.07,
                                color: _isShuffleEnabled
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withOpacity(0.6),
                                onPressed: _toggleShuffle,
                              ),
                              IconButton(
                                icon: Icon(
                                  _loopMode == LoopMode.off
                                      ? Icons.repeat
                                      : _loopMode == LoopMode.all
                                          ? Icons.repeat
                                          : Icons.repeat_one,
                                ),
                                iconSize: height * 0.07,
                                color: _loopMode != LoopMode.off
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withOpacity(0.6),
                                onPressed: _toggleRepeat,
                              ),
                              IconButton(
                                icon: Icon(
                                  _isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                                iconSize: height * 0.07,
                                color: _isLiked
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withOpacity(0.6),
                                onPressed: _toggleLikeStatus,
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Icon(Icons.volume_down,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7)),
                                Expanded(
                                  child: Slider(
                                    value: _currentVolume,
                                    min: 0.0,
                                    max: 1.0,
                                    activeColor: colorScheme.primary,
                                    inactiveColor:
                                        colorScheme.primary.withOpacity(0.3),
                                    onChanged: (value) {
                                      _setVolume(value);
                                    },
                                  ),
                                ),
                                Icon(Icons.volume_up,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.7)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
