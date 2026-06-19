import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ingv_app/data/models/event_attachment.dart';
import 'package:ingv_app/data/repositories/media_kit_player_interface.dart';

class VideoPlayerViewModel extends ChangeNotifier {
  final IVideoPlayerRepository videoRepository;
  final EventAttachment attachment;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isPlaying = false;
  bool isMuted = false;
  Object? initializationError;

  VideoController get controller => videoRepository.controller;

  VideoPlayerViewModel({
    required this.videoRepository,
    required this.attachment,
  }) {
    _initStreams();
  }

  void _initStreams() {
    final player = videoRepository.player;

    _subscriptions.add(
      player.stream.playing.listen((playing) {
        isPlaying = playing;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      player.stream.duration.listen((d) {
        duration = d;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      player.stream.position.listen((p) {
        position = p;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      player.stream.volume.listen((volume) {
        isMuted = volume == 0;
        notifyListeners();
      }),
    );
  }

  Future<void> initializeVideo() async {
    try {
      final source = attachment.hasAssetPath
          ? attachment.assetPath
          : attachment.localPath;
      if (source == null || source.isEmpty) {
        throw StateError('Missing local video source');
      }
      await videoRepository.initialize(source);
    } catch (error) {
      initializationError = error;
      notifyListeners();
    }
  }

  double get videoAspectRatio {
    final state = videoRepository.player.state;
    final width = (state.width ?? 0).toDouble();
    final height = (state.height ?? 0).toDouble();
    return (width <= 0 || height <= 0) ? 16 / 9 : width / height;
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await videoRepository.pause();
    } else {
      await videoRepository.play();
    }
  }

  Future<void> toggleMute() async {
    await videoRepository.setVolume(isMuted ? 100 : 0);
  }

  Future<void> seekTo(double milliseconds) async {
    await videoRepository.seek(Duration(milliseconds: milliseconds.toInt()));
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    videoRepository.dispose();
    super.dispose();
  }
}
