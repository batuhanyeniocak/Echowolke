import 'package:flutter/material.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';

class PlayerScreen extends StatefulWidget {
  final Track track;

  const PlayerScreen({Key? key, required this.track}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isCurrentTrack = false;
  bool _isDragging = false;

  late StreamSubscription _playerStateSubscription;
  late StreamSubscription _positionSubscription;
  late StreamSubscription _durationSubscription;

  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePlayer();
    _setupListeners();
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

  void _initializePlayer() async {
    if (_audioPlayerService.currentTrack?.id != widget.track.id) {
      await _audioPlayerService.playTrack(widget.track);
    }
    _updateCurrentState();
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
  }

  void _updateCurrentState() {
    if (mounted) {
      final currentTrack = _audioPlayerService.currentTrack;
      final newIsCurrentTrack = currentTrack?.id == widget.track.id;
      final newIsPlaying = newIsCurrentTrack && _audioPlayerService.isPlaying;

      setState(() {
        _isCurrentTrack = newIsCurrentTrack;
        _isPlaying = newIsPlaying;
        _totalDuration = Duration(seconds: widget.track.duration);
      });

      _updateAnimations();
    }
  }

  void _updatePlayingState() {
    final currentTrack = _audioPlayerService.currentTrack;
    final newIsCurrentTrack = currentTrack?.id == widget.track.id;
    final newIsPlaying = newIsCurrentTrack && _audioPlayerService.isPlaying;

    if (mounted &&
        (_isCurrentTrack != newIsCurrentTrack || _isPlaying != newIsPlaying)) {
      setState(() {
        _isCurrentTrack = newIsCurrentTrack;
        _isPlaying = newIsPlaying;
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
      await _audioPlayerService.playTrack(widget.track);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
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

  Widget _buildCoverArt() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight;
        final double availableWidth = constraints.maxWidth;
        final double maxSize = (availableHeight * 0.8).clamp(200.0, 280.0);
        final double actualSize =
            maxSize > availableWidth ? availableWidth * 0.8 : maxSize;

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
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.2),
                              spreadRadius: 10,
                              blurRadius: 30,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Stack(
                            children: [
                              Image.network(
                                widget.track.coverUrl,
                                width: actualSize,
                                height: actualSize,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: actualSize,
                                    height: actualSize,
                                    color: Colors.grey[400],
                                    child: Icon(
                                      Icons.music_note,
                                      color: Colors.white,
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey[800],
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: Colors.grey[800],
            ),
            onPressed: () {},
          ),
        ],
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
                      color: Colors.white,
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
                    child: Column(
                      children: [
                        Column(
                          children: [
                            Text(
                              widget.track.title,
                              style: TextStyle(
                                fontSize: height * 0.09,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: height * 0.015),
                            Text(
                              widget.track.artist,
                              style: TextStyle(
                                fontSize: height * 0.07,
                                color: Colors.grey[600],
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
                                activeColor: Theme.of(context).primaryColor,
                                inactiveColor: Colors.grey[300],
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
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: height * 0.05,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_totalDuration),
                                    style: TextStyle(
                                      color: Colors.grey[600],
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
                              icon: const Icon(Icons.skip_previous),
                              iconSize: buttonSize * 0.5,
                              color: Colors.grey[700],
                              onPressed: () {},
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
                                  color: Theme.of(context).primaryColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      key: ValueKey(_isPlaying),
                                      color: Colors.white,
                                      size: buttonSize * 0.5,
                                    ),
                                  ),
                                  onPressed: _handlePlayPause,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              iconSize: buttonSize * 0.5,
                              color: Colors.grey[700],
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Icon(Icons.shuffle,
                                size: height * 0.07, color: Colors.grey),
                            Icon(Icons.repeat,
                                size: height * 0.07, color: Colors.grey),
                            Icon(Icons.favorite_border,
                                size: height * 0.07, color: Colors.grey),
                            Icon(Icons.playlist_add,
                                size: height * 0.07, color: Colors.grey),
                          ],
                        ),
                        SizedBox(height: height * 0.02),
                      ],
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
