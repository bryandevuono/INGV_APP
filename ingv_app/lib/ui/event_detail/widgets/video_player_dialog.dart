import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_attachment.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerDialog extends StatefulWidget {
  final EventAttachment attachment;
  final Future<void> Function()? onOpenExternally;

  const VideoPlayerDialog({
    super.key,
    required this.attachment,
    this.onOpenExternally,
  });

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late final Player _player;
  late final VideoController _controller;
  late final Future<void> _initializeFuture;
  final GlobalKey<VideoState> _videoKey = GlobalKey<VideoState>();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isMuted = false;
  Object? _initializationError;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _initializeFuture = _initialize();

    _subscriptions.add(
      _player.stream.playing.listen((playing) {
        if (!mounted) return;
        setState(() {
          _isPlaying = playing;
        });
      }),
    );
    _subscriptions.add(
      _player.stream.duration.listen((duration) {
        if (!mounted) return;
        setState(() {
          _duration = duration;
        });
      }),
    );
    _subscriptions.add(
      _player.stream.position.listen((position) {
        if (!mounted) return;
        setState(() {
          _position = position;
        });
      }),
    );
    _subscriptions.add(
      _player.stream.volume.listen((volume) {
        if (!mounted) return;
        setState(() {
          _isMuted = volume == 0;
        });
      }),
    );
  }

  Future<void> _initialize() async {
    try {
      final source = widget.attachment.hasAssetPath
          ? widget.attachment.assetPath
          : widget.attachment.localPath;
      if (source == null || source.isEmpty) {
        throw StateError('Missing local video source');
      }

      await _player.open(Media(source), play: false);
      await _player.setPlaylistMode(PlaylistMode.loop);
      await _player.seek(Duration.zero);
      await _player.setVolume(100);
    } catch (error) {
      _initializationError = error;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<void>(
              future: _initializeFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildPoster(),
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ],
                  );
                }

                if (_initializationError != null) {
                  return _buildFallbackState();
                }

                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _videoAspectRatio,
                          child: Video(
                            key: _videoKey,
                            controller: _controller,
                            fit: BoxFit.contain,
                            controls: NoVideoControls,
                          ),
                        ),
                      ),
                    ),
                    _buildControls(),
                  ],
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (_duration > Duration.zero)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.attachment.fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.attachment.createdAt != null
                            ? widget.attachment.createdAt!.toLocal().toString()
                            : widget.attachment.formattedSize,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double get _videoAspectRatio {
    final width = (_player.state.width ?? 0).toDouble();
    final height = (_player.state.height ?? 0).toDouble();
    if (width <= 0 || height <= 0) {
      return 16 / 9;
    }
    return width / height;
  }

  Widget _buildControls() {
    final durationMs = _duration.inMilliseconds;
    final maxMs = durationMs <= 0 ? 1 : durationMs;
    final positionMs = _position.inMilliseconds.clamp(0, maxMs);

    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: positionMs.toDouble(),
              min: 0,
              max: maxMs.toDouble(),
              onChanged: durationMs <= 0
                  ? null
                  : (value) async {
                      await _player.seek(Duration(milliseconds: value.toInt()));
                    },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () async {
                  if (_isPlaying) {
                    await _player.pause();
                  } else {
                    await _player.play();
                  }
                },
              ),
              Expanded(
                child: Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await _player.setVolume(_isMuted ? 100 : 0);
                },
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: () async {
                  await _videoKey.currentState?.toggleFullscreen();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackState() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPoster(),
        Container(
          color: Colors.black54,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This local video could not be played in-app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.attachment.formattedSize,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (widget.onOpenExternally != null) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await widget.onOpenExternally!.call();
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Externally'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPoster() {
    if (widget.attachment.isVideo) {
      return _DialogVideoPoster(attachment: widget.attachment);
    }

    final posterPath = widget.attachment.previewPath;
    if (widget.attachment.hasAssetPath && posterPath != null) {
      return Image.asset(
        posterPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPosterFallback(),
      );
    }

    if (posterPath != null) {
      return Image.file(
        File(posterPath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPosterFallback(),
      );
    }

    return _buildPosterFallback();
  }

  Widget _buildPosterFallback() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 72),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours == 0) {
      return '$minutes:$seconds';
    }
    return '$hours:$minutes:$seconds';
  }
}

class _DialogVideoPoster extends StatefulWidget {
  final EventAttachment attachment;

  const _DialogVideoPoster({required this.attachment});

  @override
  State<_DialogVideoPoster> createState() => _DialogVideoPosterState();
}

class _DialogVideoPosterState extends State<_DialogVideoPoster> {
  Player? _player;
  VideoController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final player = Player();
      final controller = VideoController(player);
      _player = player;
      _controller = controller;

      if (widget.attachment.hasAssetPath) {
        await player.open(Media(widget.attachment.assetPath!), play: false);
      } else {
        await player.open(Media(widget.attachment.localPath!), play: false);
      }
      await player.seek(Duration.zero);

      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _ready = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _ready = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready && _controller != null && _player != null) {
      final widthValue = (_player!.state.width ?? 0).toDouble();
      final heightValue = (_player!.state.height ?? 0).toDouble();
      final width = widthValue <= 0 ? 16.0 : widthValue;
      final height = heightValue <= 0 ? 9.0 : heightValue;
      return FittedBox(
        fit: BoxFit.contain,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: width,
          height: height,
          child: Video(controller: _controller!, controls: NoVideoControls),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 72),
      ),
    );
  }
}
