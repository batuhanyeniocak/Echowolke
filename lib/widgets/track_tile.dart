import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../screens/player_screen.dart';

class TrackTile extends StatefulWidget {
  final Track track;
  final String formattedDuration;
  final VoidCallback? onTap;

  const TrackTile({
    Key? key,
    required this.track,
    this.formattedDuration = '00:00',
    this.onTap,
  }) : super(key: key);

  @override
  State<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> with TickerProviderStateMixin {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  bool isPlaying = false;
  bool isCurrentTrack = false;
  late StreamSubscription _playerStateSubscription;
  late AnimationController _playingAnimationController;
  late Animation<double> _playingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeListeners();
    _updateCurrentState();
  }

  void _initializeAnimations() {
    _playingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _playingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _playingAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeListeners() {
    _playerStateSubscription =
        _audioPlayerService.audioPlayer.playerStateStream.listen((playerState) {
      if (mounted) {
        _updatePlayingState();
      }
    });

    _audioPlayerService.audioPlayer.positionStream.listen((position) {
      if (mounted && isCurrentTrack) {}
    });

    _audioPlayerService.audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {}
    });

    _audioPlayerService.currentTrackStream.listen((track) {
      if (mounted) {
        _updatePlayingState();
      }
    });
  }

  void _updateCurrentState() {
    if (mounted) {
      final currentTrack = _audioPlayerService.currentTrack;
      final newIsCurrentTrack = currentTrack?.id == widget.track.id;
      final newIsPlaying = newIsCurrentTrack && _audioPlayerService.isPlaying;

      setState(() {
        isCurrentTrack = newIsCurrentTrack;
        isPlaying = newIsPlaying;
      });

      _updateAnimations();
    }
  }

  void _updatePlayingState() {
    final currentTrack = _audioPlayerService.currentTrack;
    final newIsCurrentTrack = currentTrack?.id == widget.track.id;
    final newIsPlaying = newIsCurrentTrack && _audioPlayerService.isPlaying;

    if (isCurrentTrack != newIsCurrentTrack || isPlaying != newIsPlaying) {
      setState(() {
        isCurrentTrack = newIsCurrentTrack;
        isPlaying = newIsPlaying;
      });

      _updateAnimations();
    }
  }

  void _updateAnimations() {
    if (isPlaying) {
      _playingAnimationController.repeat(reverse: true);
    } else {
      _playingAnimationController.stop();
      _playingAnimationController.reset();
    }
  }

  @override
  void dispose() {
    _playerStateSubscription.cancel();
    _playingAnimationController.dispose();
    super.dispose();
  }

  String _formatPlayCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildPlayingIndicator() {
    if (!isPlaying) return const SizedBox.shrink();

    return Positioned(
      bottom: 2,
      right: 2,
      child: AnimatedBuilder(
        animation: _playingAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _playingAnimation.value,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.volume_up,
                color: Colors.white,
                size: 10,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isCurrentTrack
            ? Theme.of(context).primaryColor.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentTrack
            ? Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: isCurrentTrack
                      ? [
                          BoxShadow(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.track.coverUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    return Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
            _buildPlayingIndicator(),
          ],
        ),
        title: Text(
          widget.track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isCurrentTrack ? FontWeight.w600 : FontWeight.w500,
            color: isCurrentTrack ? Theme.of(context).primaryColor : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isCurrentTrack
                    ? Theme.of(context).primaryColor.withOpacity(0.8)
                    : Colors.grey[600],
                fontWeight:
                    isCurrentTrack ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  widget.formattedDuration,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.play_circle_outline,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatPlayCount(widget.track.playCount),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrentTrack
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : null,
          ),
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                key: ValueKey(isPlaying),
                color: isCurrentTrack
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
                size: 28,
              ),
            ),
            onPressed: _handlePlayPause,
          ),
        ),
        onTap: widget.onTap,
      ),
    );
  }
}
