import 'package:flutter/material.dart';

import '../../domain/events/game_events.dart';
import '../../domain/models/board.dart';
import 'reaction_animation.dart';
import 'reaction_board_state.dart';

class ReactionAnimationConfig {
  /// How long one reaction depth takes to play.
  ///
  /// The number of animations inside the wave does not affect
  /// this duration.
  static const Duration depthDuration = Duration(milliseconds: 250);
}

class ReactionStateUpdate {
  final int row;
  final int col;
  final int virusCount;
  final int chainDepth;
  final int? playerId;
  const ReactionStateUpdate({
    required this.row,
    required this.col,
    required this.virusCount,
    required this.chainDepth,
    required this.playerId,
  });
}

class ReactionWave {
  final int depth;
  final List<ReactionAnimation> animations;
  final List<ReactionStateUpdate> stateUpdates;
  const ReactionWave({
    required this.depth,
    required this.animations,
    required this.stateUpdates,
  });

  /// All explosions that happen at this depth.
  List<ReactionAnimation> get explosions {
    return animations
        .where((animation) => animation.isExplosion)
        .toList(growable: false);
  }

  /// All viruses that spread at this depth.
  List<ReactionAnimation> get spreads {
    return animations
        .where((animation) => animation.isSpread)
        .toList(growable: false);
  }

  int get explosionCount => explosions.length;

  int get spreadCount => spreads.length;

  bool get isEmpty => animations.isEmpty;

  bool get hasExplosions => explosionCount > 0;

  bool get hasSpreads => spreadCount > 0;
}

class ReactionTimeline {
  final List<ReactionWave> waves;
  final List<ReactionBoardState> states;
  const ReactionTimeline({
    required this.waves,
    required this.states,
  });

  bool get isEmpty => waves.isEmpty;

  int get depthCount => waves.length;

  int get maxDepth => isEmpty ? 0 : waves.last.depth;

  int get totalExplosions {
    return waves.fold(
      0,
      (total, wave) => total + wave.explosionCount,
    );
  }

  int get totalSpreads {
    return waves.fold(
      0,
      (total, wave) => total + wave.spreadCount,
    );
  }

  ReactionBoardState? stateAtDepth(int depth) {
    final index = waves.indexWhere(
      (wave) => wave.depth == depth,
    );

    if (index == -1 || index >= states.length) {
      return null;
    }

    return states[index];
  }

  /// Total playback duration.
  ///
  /// Example:
  /// 1 depth  = 250ms
  /// 2 depths = 500ms
  /// 3 depths = 750ms
  Duration get totalDuration {
    return ReactionAnimationConfig.depthDuration * depthCount;
  }

  ReactionWave? waveAtDepth(int depth) {
    for (final wave in waves) {
      if (wave.depth == depth) {
        return wave;
      }
    }

    return null;
  }

  factory ReactionTimeline.fromEvents(
      {required List<GameEvent> events, required Board initialBoard}) {
    final animationsByDepth = <int, List<ReactionAnimation>>{};
    final stateUpdatesByDepth = <int, List<ReactionStateUpdate>>{};
    for (final event in events) {
      if (event is VirusExploded) {
        final animation = ReactionAnimation.fromExplosion(event);

        animationsByDepth
            .putIfAbsent(animation.chainDepth, () => <ReactionAnimation>[])
            .add(animation);
      } else if (event is VirusSpread) {
        final animation = ReactionAnimation.fromSpread(event);

        animationsByDepth
            .putIfAbsent(animation.chainDepth, () => <ReactionAnimation>[])
            .add(animation);
      } else if (event is CellUpdated && event.chainDepth > 0) {
        final stateUpdate = ReactionStateUpdate(
          row: event.row,
          col: event.col,
          virusCount: event.virusCount,
          playerId: event.playerId,
          chainDepth: event.chainDepth,
        );

        stateUpdatesByDepth
            .putIfAbsent(event.chainDepth, () => <ReactionStateUpdate>[])
            .add(stateUpdate);
      }
    }

    final allDepths = <int>{
      ...animationsByDepth.keys,
      ...stateUpdatesByDepth.keys,
    }.toList()
      ..sort();

    if (allDepths.isEmpty) {
      return const ReactionTimeline(
        waves: <ReactionWave>[],
        states: <ReactionBoardState>[],
      );
    }

    final waves = <ReactionWave>[];
    final states = <ReactionBoardState>[];
    var currentState = ReactionBoardState.fromBoard(initialBoard);
    for (final depth in allDepths) {
      final animations = animationsByDepth[depth] ?? <ReactionAnimation>[];

      final stateUpdates =
          stateUpdatesByDepth[depth] ?? <ReactionStateUpdate>[];

      waves.add(
        ReactionWave(
          depth: depth,
          animations: List.unmodifiable(animations),
          stateUpdates: List.unmodifiable(stateUpdates),
        ),
      );
    }
    for (final wave in waves) {
      currentState = currentState.applyWave(wave);
      states.add(currentState);
      debugPrint(
        'Wave depth=${wave.depth} '
        'animations=${wave.animations.length} '
        'stateUpdates=${wave.stateUpdates.length} '
        'explosions=${wave.explosionCount} '
        'spreads=${wave.spreadCount}',
      );
      debugPrint(
        '[ReactionPath] depth=${wave.depth} | '
        'spreads=${wave.spreadCount}',
      );

      for (final spread in wave.spreads) {
        debugPrint(
          '[ReactionPath] '
          '(${spread.row},${spread.col}) '
          '-> '
          '(${spread.toRow},${spread.toCol}) '
          '| direction=${spread.direction}',
        );
      }
    }
    return ReactionTimeline(
      waves: List.unmodifiable(waves),
      states: List.unmodifiable(states),
    );
  }
}
