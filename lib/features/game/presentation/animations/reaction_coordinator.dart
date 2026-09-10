import 'package:flutter/material.dart';

import '../../domain/models/board.dart';
import '../../domain/services/game_engine.dart';
import 'reaction_animation_controller.dart';
import 'reaction_timeline.dart';

class ReactionCoordinator {
  final ReactionAnimationController animationController;

  ReactionCoordinator({
    required this.animationController,
  });

  void handleTurnResult(
    GameEngineResult result, {
    required Board initialBoard,
  }) {
    final timeline = ReactionTimeline.fromEvents(
      events: result.events,
      initialBoard: initialBoard,
    );
    if (timeline.isEmpty) {
      return;
    }
    debugPrint(
      'Reaction: depth=${timeline.maxDepth}, '
      'waves=${timeline.depthCount}, '
      'explosions=${timeline.totalExplosions}, '
      'spreads=${timeline.totalSpreads}',
    );
    animationController.play(timeline);
  }

  void dispose() {
    animationController.stop();
  }
}
