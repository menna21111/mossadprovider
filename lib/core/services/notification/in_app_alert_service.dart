import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Plays `assets/sound/scuess_order.mp3` + vibrate on WebSocket notifications.
class InAppAlertService {
  InAppAlertService._();

  static final AudioPlayer _player = AudioPlayer();
  static DateTime? _lastPlayedAt;

  static Future<void> playIncoming() async {
    final now = DateTime.now();
    if (_lastPlayedAt != null &&
        now.difference(_lastPlayedAt!) < const Duration(milliseconds: 900)) {
      return;
    }
    _lastPlayedAt = now;

    await Future.wait([
      _vibrate(),
      _playSound(),
    ]);
  }

  static Future<void> _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        await Vibration.vibrate(pattern: [0, 220, 90, 180]);
        return;
      }
    } catch (_) {}

    try {
      await HapticFeedback.vibrate();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> _playSound() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1);
      await _player.play(
        AssetSource('sound/scuess_order.mp3'),
        mode: PlayerMode.mediaPlayer,
      );
    } catch (e) {
      debugPrint('InAppAlertService sound failed: $e');
    }
  }
}
