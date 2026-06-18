import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'media_kit_player_interface.dart';

class MediaKitPlayerRepository implements IVideoPlayerRepository {
  late final Player _player;
  late final VideoController _controller;

  MediaKitPlayerRepository() {
    _player = Player();
    _controller = VideoController(_player);
  }

  @override
  Player get player => _player;

  @override
  VideoController get controller => _controller;

  @override
  Future<void> initialize(String source) async {
    await _player.open(Media(source), play: false);
    await _player.setPlaylistMode(PlaylistMode.loop);
    await _player.seek(Duration.zero);
    await _player.setVolume(100);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  void dispose() {
    _player.dispose();
  }
}
