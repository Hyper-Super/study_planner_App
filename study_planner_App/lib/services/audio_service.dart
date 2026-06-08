import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays in-app sounds — currently used for timer completion.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();

  /// Call when a Pomodoro / break timer finishes.
  /// Uses a built-in system sound (no asset file needed).
  Future<void> playTimerComplete() async {
    try {
      // Play a tri-tone-style beep sequence using AudioPlayer's URL source.
      // We use a royalty-free short chime hosted publicly so no asset bundling needed.
      // Falls back silently if the device has no network or the URL is unreachable.
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.play(
        UrlSource(
          'https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3',
        ),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('[AudioService] playTimerComplete error: $e');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
