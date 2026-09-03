import 'dart:collection';
import 'package:flutter/material.dart';

import '../events/game_events.dart';
import '../events/game_log_context.dart';
import '../models/board.dart';
import '../models/position.dart';
import '../models/virus_model.dart';
import 'board_evaluator.dart';

class SimulationResult {
  final Board updatedBoard;
  final List<GameEvent> events;
  final int totalExplosions;
  final int totalSpreads;
  final int maxChainDepth;

  const SimulationResult({
    required this.updatedBoard,
    required this.events,
    required this.totalExplosions,
    required this.totalSpreads,
    required this.maxChainDepth,
  });
}

class ReactionSimulator {
  final BoardEvaluator evaluator;

  const ReactionSimulator(this.evaluator);

  SimulationResult simulate({
    required Board board,
    required Position target,
    required int playerId,
    required GameLogContext context,
  }) {
    final events = <GameEvent>[];
    int totalExplosions = 0;
    int totalSpreads = 0;
    int maxChainDepth = 0;

    // Maximum number of micro-events recorded per turn inorder to manage memory
    const int maxEventCapacity = 50;

    // Deep copy mutable grid
    final grid = board.cells.map((r) => List<VirusModel>.from(r)).toList();

    // 1. Initial placement
    final initialCell = grid[target.row][target.col];
    grid[target.row][target.col] = initialCell.increment(playerId);

    events.add(CellUpdated(
      context,
      row: target.row,
      col: target.col,
      virusCount: grid[target.row][target.col].virusCount,
    ));

    // 2. Queue for  chain reactions: stores (Position, ChainDepth)
    final queue = Queue<(Position, int)>();

    if (grid[target.row][target.col].virusCount >=
        evaluator.getCriticalMass(target)) {
      events.add(ReactionStarted(
        context,
        originRow: target.row,
        originCol: target.col,
      ));
      queue.add((target, 1));
    }

    int iterations = 0;
    // 3. Process explosions
    while (queue.isNotEmpty) {
      iterations++;
      // Safety threshold against infinite bouncing loops
      if (iterations > 10000) {
        debugPrint(
            'CRITICAL: ReactionSimulator loop infinite bounce detected!');
        break;
      }
      final (currentPos, depth) = queue.removeFirst();
      final currentCell = grid[currentPos.row][currentPos.col];
      final threshold = evaluator.getCriticalMass(currentPos);

      if (currentCell.virusCount < threshold) continue;

      if (depth > maxChainDepth) maxChainDepth = depth;
      totalExplosions++;
      if (events.length < maxEventCapacity) {
        events.add(VirusExploded(
          context,
          row: currentPos.row,
          col: currentPos.col,
          chainDepth: depth,
        ));
      }

      // Subtract exploded viruses and reset cell if empty
      final remainingCount = currentCell.virusCount - threshold;
      grid[currentPos.row][currentPos.col] = remainingCount == 0
          ? const VirusModel.empty()
          : VirusModel(virusCount: remainingCount, playerId: playerId);

      if (events.length < maxEventCapacity) {
        events.add(CellUpdated(
          context,
          row: currentPos.row,
          col: currentPos.col,
          virusCount: grid[currentPos.row][currentPos.col].virusCount,
        ));
      }

      // Spread 1 virus to each neighbor
      final neighbors = evaluator.getNeighbors(currentPos);
      for (final neighborPos in neighbors) {
        totalSpreads++;
        if (events.length < maxEventCapacity) {
          events.add(VirusSpread(
            context,
            fromRow: currentPos.row,
            fromCol: currentPos.col,
            toRow: neighborPos.row,
            toCol: neighborPos.col,
            chainDepth: depth,
          ));
        }

        final targetCell = grid[neighborPos.row][neighborPos.col];
        grid[neighborPos.row][neighborPos.col] = targetCell.increment(playerId);

        events.add(CellUpdated(
          context,
          row: neighborPos.row,
          col: neighborPos.col,
          virusCount: grid[neighborPos.row][neighborPos.col].virusCount,
        ));

        if (grid[neighborPos.row][neighborPos.col].virusCount >=
            evaluator.getCriticalMass(neighborPos)) {
          queue.add((neighborPos, depth + 1));
        }
      }
    }

    return SimulationResult(
      updatedBoard: Board(rows: board.rows, cols: board.cols, cells: grid),
      events: events,
      totalExplosions: totalExplosions,
      totalSpreads: totalSpreads,
      maxChainDepth: maxChainDepth,
    );
  }
}
