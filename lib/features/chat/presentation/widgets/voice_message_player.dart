import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/styles_manager.dart';

class VoiceMessagePlayer extends StatefulWidget {
  const VoiceMessagePlayer({
    super.key,
    required this.url,
    required this.durationSeconds,
    required this.isMine,
  });

  final String url;
  final int durationSeconds;
  final bool isMine;

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final _player = AudioPlayer();
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  /// Fixed “tone” heights for the waveform (design-like bars).
  static const List<double> _tones = [
    0.35, 0.55, 0.28, 0.72, 0.42, 0.88, 0.50, 0.30, 0.65, 0.40,
    0.78, 0.48, 0.32, 0.90, 0.55, 0.38, 0.70, 0.45, 0.82, 0.36,
    0.60, 0.44, 0.75, 0.50, 0.33, 0.68, 0.42, 0.85, 0.48, 0.30,
  ];

  @override
  void initState() {
    super.initState();
    _duration = Duration(seconds: widget.durationSeconds);
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playing = false;
        _position = Duration.zero;
      });
    });
    _player.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((d) {
      if (!mounted || d.inMilliseconds <= 0) return;
      setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (widget.url.isEmpty) return;
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    final source = widget.url.startsWith('http')
        ? UrlSource(widget.url)
        : DeviceFileSource(widget.url);
    if (_position.inMilliseconds > 0) {
      await _player.resume();
    } else {
      await _player.play(source);
    }
    if (mounted) setState(() => _playing = true);
  }

  String _label() {
    final total = _duration.inSeconds > 0
        ? _duration
        : Duration(seconds: widget.durationSeconds);
    final shown = _playing || _position.inMilliseconds > 0 ? _position : total;
    final m = shown.inMinutes.remainder(60);
    final s = shown.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isMine = widget.isMine;
    final fg = isMine ? Colors.white : const Color(0xFF161616);
    final played = isMine
        ? Colors.white.withValues(alpha: 0.45)
        : const Color(0xFF9A9A9A);
    final remaining = isMine ? Colors.white : const Color(0xFF161616);

    final totalMs = (_duration.inMilliseconds > 0
            ? _duration.inMilliseconds
            : widget.durationSeconds * 1000)
        .clamp(1, 1 << 30);
    final progress = (_position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    // Keep voice controls LTR like the design (duration | wave | play).
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 200.w,
        child: Row(
          children: [
            Text(
              _label(),
              style: getMediumStyle(fontSize: 12.sp, color: fg),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: SizedBox(
                height: 28.h,
                child: CustomPaint(
                  painter: _WaveformPainter(
                    tones: _tones,
                    progress: progress,
                    playedColor: played,
                    remainingColor: remaining,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            InkWell(
              onTap: widget.url.isEmpty ? null : _toggle,
              borderRadius: BorderRadius.circular(20.r),
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: fg,
                  size: 26.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.tones,
    required this.progress,
    required this.playedColor,
    required this.remainingColor,
  });

  final List<double> tones;
  final double progress;
  final Color playedColor;
  final Color remainingColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (tones.isEmpty || size.width <= 0 || size.height <= 0) return;

    final count = tones.length;
    final gap = size.width / (count * 2.2);
    final barWidth = math.max(2.0, gap * 0.9);
    final totalBarsWidth = count * barWidth + (count - 1) * gap;
    final startX = (size.width - totalBarsWidth) / 2;
    final midY = size.height / 2;
    final playedUntil = (progress * count).floor();

    for (var i = 0; i < count; i++) {
      final tone = tones[i].clamp(0.15, 1.0);
      final barHeight = size.height * tone;
      final x = startX + i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, midY),
          width: barWidth,
          height: barHeight,
        ),
        Radius.circular(barWidth),
      );
      final paint = Paint()
        ..color = i < playedUntil ? playedColor : remainingColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.playedColor != playedColor ||
        oldDelegate.remainingColor != remainingColor;
  }
}
