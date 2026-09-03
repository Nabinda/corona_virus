import 'game_log_context.dart';

/// Base class for all game lifecycle, action, and reaction events.
sealed class GameEvent {
  final GameLogContext context;
  final DateTime timestamp;

  GameEvent(this.context) : timestamp = DateTime.now();
}

// ---------------------------------------------------------------------------
// Turn & Move Lifecycle Events
// ---------------------------------------------------------------------------

/// Emitted when a turn begins for a player.
class TurnStarted extends GameEvent {
  TurnStarted(super.context);
}

/// Emitted when a player attempts to tap/play on a cell.
class MoveAttempted extends GameEvent {
  final int row;
  final int col;

  MoveAttempted(super.context, {required this.row, required this.col});
}

/// Emitted when a move is validated and accepted by the engine.
class MoveAccepted extends GameEvent {
  final int row;
  final int col;

  MoveAccepted(super.context, {required this.row, required this.col});
}

/// Emitted when a move is rejected (e.g., clicking on another player's virus).
class MoveRejected extends GameEvent {
  final int row;
  final int col;
  final String reason;

  MoveRejected(
    super.context, {
    required this.row,
    required this.col,
    required this.reason,
  });
}

/// Emitted when a player's full turn completes.
class TurnEnded extends GameEvent {
  final Duration duration;

  TurnEnded(super.context, {required this.duration});
}

// ---------------------------------------------------------------------------
// Board & Reaction Events
// ---------------------------------------------------------------------------

/// Emitted when a cell's count changes without exploding.
class CellUpdated extends GameEvent {
  final int row;
  final int col;
  final int virusCount;

  CellUpdated(
    super.context, {
    required this.row,
    required this.col,
    required this.virusCount,
  });
}

/// Emitted when a move triggers the start of a chain reaction sequence.
class ReactionStarted extends GameEvent {
  final int originRow;
  final int originCol;

  ReactionStarted(super.context,
      {required this.originRow, required this.originCol});
}

/// Emitted whenever a cell reaches critical mass and bursts.
class VirusExploded extends GameEvent {
  final int row;
  final int col;
  final int chainDepth;

  VirusExploded(
    super.context, {
    required this.row,
    required this.col,
    required this.chainDepth,
  });
}

/// Emitted when an exploding cell distributes a virus to an adjacent neighbor.
class VirusSpread extends GameEvent {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final int chainDepth;

  VirusSpread(
    super.context, {
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.chainDepth,
  });
}

/// Emitted once an entire cascading chain reaction settles.
class ReactionChainCompleted extends GameEvent {
  final Duration duration;
  final int maxChainDepth;
  final int totalExplosions;
  final int totalSpreads;

  ReactionChainCompleted(
    super.context, {
    required this.duration,
    required this.maxChainDepth,
    required this.totalExplosions,
    required this.totalSpreads,
  });
}

// ---------------------------------------------------------------------------
// Match Progression & Outcome Events
// ---------------------------------------------------------------------------

/// Emitted when a player loses all their cells and is removed from active play.
class PlayerEliminated extends GameEvent {
  final int eliminatedPlayerId;
  final String eliminatedPlayerName;
  final int remainingPlayers;

  PlayerEliminated(
    super.context, {
    required this.eliminatedPlayerId,
    required this.eliminatedPlayerName,
    required this.remainingPlayers,
  });
}

/// Emitted when only one player remains and wins the match.
class GameFinished extends GameEvent {
  final int winnerPlayerId;
  final String winnerPlayerName;
  final Duration matchDuration;

  GameFinished(
    super.context, {
    required this.winnerPlayerId,
    required this.winnerPlayerName,
    required this.matchDuration,
  });
}
