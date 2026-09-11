import 'dart:collection';

import 'package:flutter/foundation.dart';

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
  final int recordedEvents;
  final int droppedEvents;

  const SimulationResult({
    required this.updatedBoard,
    required this.events,
    required this.totalExplosions,
    required this.totalSpreads,
    required this.maxChainDepth,
    required this.recordedEvents,
    required this.droppedEvents,
  });

  bool get eventsTruncated => droppedEvents > 0;
}

class ReactionSimulator {
  final BoardEvaluator evaluator;

  /// Maximum number of events retained for one simulation.
  ///
  /// This does NOT limit the reaction.
  /// It only limits event objects kept in memory.
  static const int maxEventCapacity = 500;

  /// Emergency protection against an unexpected infinite loop.
  static const int maxIterations = 10000;

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
    int droppedEvents = 0;

    // -------------------------------------------------------------
    // EVENT RECORDER
    // -------------------------------------------------------------

    void recordEvent(GameEvent event) {
      if (events.length < maxEventCapacity) {
        events.add(event);
      } else {
        droppedEvents++;
      }
    }

    // -------------------------------------------------------------
    // COPY BOARD
    // -------------------------------------------------------------

    final grid = board.cells.map((row) => List<VirusModel>.from(row)).toList();

    // -------------------------------------------------------------
    // INITIAL PLACEMENT
    // -------------------------------------------------------------

    final initialCell = grid[target.row][target.col];

    final updatedInitialCell = initialCell.increment(playerId);

    grid[target.row][target.col] = updatedInitialCell;

    recordEvent(
      CellUpdated(
        context,
        row: target.row,
        col: target.col,
        virusCount: updatedInitialCell.virusCount,
        playerId: updatedInitialCell.playerId,
        chainDepth: 0,
      ),
    );

    // -------------------------------------------------------------
    // INITIAL CRITICAL MASS
    // -------------------------------------------------------------

    final initialCriticalMass = evaluator.getCriticalMass(target);

    final shouldExplode = updatedInitialCell.virusCount >= initialCriticalMass;

    if (shouldExplode) {
      recordEvent(
        ReactionStarted(
          context,
          originRow: target.row,
          originCol: target.col,
        ),
      );
    }

    // -------------------------------------------------------------
    // REACTION QUEUE
    // -------------------------------------------------------------

    final queue = Queue<(Position, int)>();

    if (shouldExplode) {
      queue.add((target, 1));
    }

    // -------------------------------------------------------------
    // PROCESS REACTIONS
    // -------------------------------------------------------------

    int iterations = 0;

    while (queue.isNotEmpty) {
      iterations++;

      // Emergency safety limit.
      if (iterations > maxIterations) {
        debugPrint(
          '[ReactionSimulator] CRITICAL: '
          'Maximum iteration limit reached '
          '($maxIterations). '
          'Reaction processing stopped.',
        );

        break;
      }

      final (currentPos, depth) = queue.removeFirst();

      final currentCell = grid[currentPos.row][currentPos.col];

      final criticalMass = evaluator.getCriticalMass(currentPos);

      // Cell may have changed since it was queued.
      if (currentCell.virusCount < criticalMass) {
        continue;
      }

      // -----------------------------------------------------------
      // STATISTICS
      // -----------------------------------------------------------

      totalExplosions++;

      if (depth > maxChainDepth) {
        maxChainDepth = depth;
      }

      // -----------------------------------------------------------
      // EXPLOSION EVENT
      // -----------------------------------------------------------

      recordEvent(
        VirusExploded(
          context,
          row: currentPos.row,
          col: currentPos.col,
          playerID: playerId,
          chainDepth: depth,
        ),
      );

      // -----------------------------------------------------------
      // REMOVE CRITICAL MASS
      // -----------------------------------------------------------

      final remainingCount = currentCell.virusCount - criticalMass;

      final remainingCell = remainingCount == 0
          ? const VirusModel.empty()
          : VirusModel(
              virusCount: remainingCount,
              playerId: playerId,
            );

      grid[currentPos.row][currentPos.col] = remainingCell;

      // -----------------------------------------------------------
      // CELL UPDATE EVENT
      // -----------------------------------------------------------

      recordEvent(
        CellUpdated(
          context,
          row: currentPos.row,
          col: currentPos.col,
          virusCount: remainingCell.virusCount,
          playerId: playerId,
          chainDepth: depth,
        ),
      );

      // -----------------------------------------------------------
      // GET NEIGHBOURS
      // -----------------------------------------------------------

      final neighbors = evaluator.getNeighbors(currentPos);

      // -----------------------------------------------------------
      // SPREAD
      // -----------------------------------------------------------

      for (final neighborPos in neighbors) {
        totalSpreads++;

        // ---------------------------------------------------------
        // SPREAD EVENT
        // ---------------------------------------------------------

        recordEvent(
          VirusSpread(
            context,
            fromRow: currentPos.row,
            fromCol: currentPos.col,
            toRow: neighborPos.row,
            toCol: neighborPos.col,
            playerId: playerId,
            chainDepth: depth,
          ),
        );

        // ---------------------------------------------------------
        // UPDATE NEIGHBOUR
        // ---------------------------------------------------------

        final targetCell = grid[neighborPos.row][neighborPos.col];

        final updatedNeighbor = targetCell.increment(playerId);

        grid[neighborPos.row][neighborPos.col] = updatedNeighbor;

        // ---------------------------------------------------------
        // CELL UPDATE EVENT
        // ---------------------------------------------------------

        recordEvent(
          CellUpdated(
            context,
            row: neighborPos.row,
            col: neighborPos.col,
            virusCount: updatedNeighbor.virusCount,
            playerId: updatedNeighbor.playerId,
            chainDepth: depth,
          ),
        );

        // ---------------------------------------------------------
        // CHECK CRITICAL MASS
        // ---------------------------------------------------------

        final neighborCriticalMass = evaluator.getCriticalMass(neighborPos);

        if (updatedNeighbor.virusCount >= neighborCriticalMass) {
          queue.add(
            (
              neighborPos,
              depth + 1,
            ),
          );
        }
      }
    }

    // -------------------------------------------------------------
    // DEBUG STATISTICS
    // -------------------------------------------------------------

    if (kDebugMode) {
      debugPrint(
        '[ReactionSimulator] '
        'explosions=$totalExplosions | '
        'spreads=$totalSpreads | '
        'maxDepth=$maxChainDepth | '
        'recordedEvents=${events.length} | '
        'droppedEvents=$droppedEvents',
      );
    }

    // -------------------------------------------------------------
    // RESULT
    // -------------------------------------------------------------

    return SimulationResult(
      updatedBoard: Board(
        rows: board.rows,
        cols: board.cols,
        cells: grid,
      ),
      events: events,
      totalExplosions: totalExplosions,
      totalSpreads: totalSpreads,
      maxChainDepth: maxChainDepth,
      recordedEvents: events.length,
      droppedEvents: droppedEvents,
    );
  }
}
