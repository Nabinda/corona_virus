import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

import 'reaction_timeline.dart';

class ReactionAnimationController extends ChangeNotifier
    implements TickerProvider {
  Ticker? _ticker;

  ReactionTimeline? _timeline;

  int _currentWaveIndex = -1;

  bool _isPlaying = false;

  Duration _elapsed = Duration.zero;

  ReactionAnimationController() {
    _ticker = createTicker(_onTick);
  }
  bool isCellMasked(int row, int col) {
    if (!_isPlaying || _timeline == null) {
      return false;
    }

    for (final wave in _timeline!.waves) {
      for (final update in wave.stateUpdates) {
        if (update.row == row && update.col == col) {
          return true;
        }
      }
    }

    return false;
  }

  ReactionTimeline? get timeline => _timeline;

  bool get isPlaying => _isPlaying;

  int get currentWaveIndex => _currentWaveIndex;

  ReactionWave? get currentWave {
    if (_timeline == null) return null;

    if (_currentWaveIndex < 0 || _currentWaveIndex >= _timeline!.waves.length) {
      return null;
    }

    return _timeline!.waves[_currentWaveIndex];
  }

  int get currentDepth => currentWave?.depth ?? 0;

  int get totalWaves => _timeline?.waves.length ?? 0;

  /// Progress through the current reaction depth.
  ///
  /// 0.0 = beginning of depth
  /// 1.0 = end of depth
  double get depthProgress {
    if (!_isPlaying || _timeline == null || currentWave == null) {
      return 0.0;
    }

    final depthDuration = ReactionAnimationConfig.depthDuration.inMicroseconds;

    if (depthDuration <= 0) {
      return 1.0;
    }

    final progress = _elapsed.inMicroseconds / depthDuration;

    return progress.clamp(0.0, 1.0);
  }

  /// Overall reaction progress.
  double get progress {
    if (_timeline == null || _timeline!.waves.isEmpty) {
      return 0.0;
    }

    final completedWaves = _currentWaveIndex < 0 ? 0 : _currentWaveIndex;

    final currentProgress = depthProgress;

    return ((completedWaves + currentProgress) / _timeline!.waves.length)
        .clamp(0.0, 1.0);
  }

  void play(ReactionTimeline timeline) {
    stop(notify: false);

    if (timeline.isEmpty) {
      return;
    }

    _timeline = timeline;
    _currentWaveIndex = 0;
    _elapsed = Duration.zero;
    _isPlaying = true;

    _ticker?.start();

    notifyListeners();
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying || _timeline == null) {
      return;
    }

    final depthDuration = ReactionAnimationConfig.depthDuration;

    final totalElapsed = elapsed;

    final totalDepths = _timeline!.waves.length;

    final depthMilliseconds = depthDuration.inMilliseconds;

    if (depthMilliseconds <= 0) {
      _finish();
      return;
    }

    final totalMilliseconds = totalDepths * depthMilliseconds;

    final elapsedMilliseconds = totalElapsed.inMilliseconds;

    if (elapsedMilliseconds >= totalMilliseconds) {
      _finish();
      return;
    }

    final waveIndex = elapsedMilliseconds ~/ depthMilliseconds;

    final millisecondsIntoWave = elapsedMilliseconds % depthMilliseconds;

    _currentWaveIndex = waveIndex;

    _elapsed = Duration(
      milliseconds: millisecondsIntoWave,
    );

    notifyListeners();
  }

  void stop({bool notify = true}) {
    _ticker?.stop();

    _timeline = null;
    _currentWaveIndex = -1;
    _elapsed = Duration.zero;
    _isPlaying = false;

    if (notify) {
      notifyListeners();
    }
  }

  void _finish() {
    _ticker?.stop();

    _isPlaying = false;

    if (_timeline != null && _timeline!.waves.isNotEmpty) {
      _currentWaveIndex = _timeline!.waves.length - 1;
      _elapsed = ReactionAnimationConfig.depthDuration;
    }

    notifyListeners();
  }

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;

    super.dispose();
  }
}
