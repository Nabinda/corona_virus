// lib/core/diagnostics/fps_tracker.dart
import 'package:flutter/scheduler.dart';
import '../logger/app_logger.dart';

class FpsTracker {
  static final FpsTracker instance = FpsTracker._();
  FpsTracker._();

  AppLogger? _logger;
  bool _isRunning = false;
  int _frameCount = 0;
  int _jankCount = 0;
  DateTime? _lastReportTime;

  void init(AppLogger logger) {
    _logger = logger;
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _lastReportTime = DateTime.now();

    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frameCount++;
      final duration = timing.totalSpan.inMilliseconds;
      if (duration > 16.6) {
        _jankCount++;
      }
    }

    final now = DateTime.now();
    if (_lastReportTime != null &&
        now.difference(_lastReportTime!).inSeconds >= 2) {
      final elapsedSec =
          now.difference(_lastReportTime!).inMilliseconds / 1000.0;
      final fps = _frameCount / elapsedSec;

      _logger?.debug(
        '[FPS_SAMPLE] FPS: ${fps.toStringAsFixed(1)} | Jank: $_jankCount frames',
        data: {
          'fps': double.parse(fps.toStringAsFixed(1)),
          'jankFrames': _jankCount,
          'totalFrames': _frameCount,
        },
      );

      _frameCount = 0;
      _jankCount = 0;
      _lastReportTime = now;
    }
  }

  void stop() {
    _isRunning = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }
}
