import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

abstract interface class IVideoPlayerRepository {
  Player get player;
  VideoController get controller;

  Future<void> initialize(String source);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  void dispose();
}
