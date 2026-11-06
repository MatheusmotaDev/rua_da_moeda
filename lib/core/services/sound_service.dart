import 'package:audioplayers/audioplayers.dart';

/// Local original WAV assets only. Audio failure never blocks the adventure.
class SoundService {
  AudioPlayer? _music, _effect;
  String? _track;
  bool enabled = true;
  double volume = .35;
  Future<void> configure(bool active, double level, {String? track}) async {
    enabled = active;
    volume = level;
    try {
      if (!active) {
        await _music?.pause();
        return;
      }
      _music ??= AudioPlayer();
      await _music!.setVolume(volume * .55);
      if (track != null && track != _track) {
        _track = track;
        await _music!.setReleaseMode(ReleaseMode.loop);
        await _music!.play(AssetSource('audio/$track.wav'));
      } else {
        await _music!.resume();
      }
    } catch (_) {
      /* Autoplay and unavailable platform audio are optional. */
    }
  }

  Future<void> effect(String name) async {
    if (!enabled) return;
    try {
      _effect ??= AudioPlayer();
      await _effect!.play(AssetSource('audio/$name.wav'), volume: volume);
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _music?.pause();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _music?.dispose();
    await _effect?.dispose();
  }
}
