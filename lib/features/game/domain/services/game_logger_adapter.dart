// lib/features/game/domain/services/game_logger_adapter.dart
import '../../../../core/logger/app_logger.dart';
import '../../../../core/logger/log_level.dart';
import '../events/game_events.dart';

class GameLoggerAdapter {
  final AppLogger _logger;

  GameLoggerAdapter(this._logger);

  /// Expose underlying logger for high-level digests and crash hooks
  AppLogger get logger => _logger;

  void handleEvent(GameEvent event) {
    final ctx = <String, dynamic>{
      'game': event.context.gameId,
      'move': event.context.moveId,
      'turn': event.context.turnNumber,
      'player': event.context.playerName,
      if (event.context.reactionId != null)
        'reaction': event.context.reactionId,
    };

    switch (event) {
      case TurnStarted _:
        _logger.info('TURN_STARTED', data: ctx);

      case MoveAttempted e:
        _logger.debug(
          'MOVE_ATTEMPTED',
          data: {...ctx, 'cell': '(${e.row},${e.col})'},
        );

      case MoveAccepted e:
        _logger.info(
          'MOVE_ACCEPTED',
          data: {...ctx, 'cell': '(${e.row},${e.col})'},
        );

      case MoveRejected e:
        _logger.warning(
          'MOVE_REJECTED',
          data: {...ctx, 'cell': '(${e.row},${e.col})', 'reason': e.reason},
        );

      case CellUpdated e:
        _logger.debug(
          'CELL_UPDATED',
          data: {
            ...ctx,
            'cell': '(${e.row},${e.col})',
            'viruses': e.virusCount
          },
        );

      case ReactionStarted e:
        _logger.info(
          'REACTION_STARTED',
          data: {...ctx, 'origin': '(${e.originRow},${e.originCol})'},
        );

      case VirusExploded e:
        _logger.info(
          'EXPLOSION',
          data: {...ctx, 'cell': '(${e.row},${e.col})', 'depth': e.chainDepth},
        );

      case VirusSpread e:
        _logger.debug(
          'VIRUS_SPREAD',
          data: {
            ...ctx,
            'from': '(${e.fromRow},${e.fromCol})',
            'to': '(${e.toRow},${e.toCol})',
            'depth': e.chainDepth,
          },
        );

      case ReactionChainCompleted e:
        final level =
            e.duration.inMilliseconds > 100 ? LogLevel.warning : LogLevel.info;
        _logger.log(
          level,
          'REACTION_COMPLETED',
          data: {
            ...ctx,
            'chainDepth': e.maxChainDepth,
            'explosions': e.totalExplosions,
            'spreads': e.totalSpreads,
          },
          duration: e.duration,
        );

      case PlayerEliminated e:
        _logger.warning(
          'PLAYER_ELIMINATED',
          data: {
            ...ctx,
            'eliminated': e.eliminatedPlayerName,
            'remaining': e.remainingPlayers,
          },
        );

      case TurnEnded e:
        _logger.info('TURN_ENDED', data: ctx, duration: e.duration);

      case GameFinished e:
        _logger.log(
          LogLevel.info,
          'GAME_FINISHED',
          data: {
            ...ctx,
            'winner': e.winnerPlayerName,
          },
          duration: e.matchDuration,
        );
    }
  }

  /// Convenience batch dispatcher
  void handleEvents(Iterable<GameEvent> events) {
    for (final event in events) {
      handleEvent(event);
    }
  }

  /// High-level turn summary written directly to disk via TelemetrySink
  void logTurnSummary({
    required int turnNumber,
    required String playerName,
    required Duration turnDuration,
    required int explosions,
    required int maxDepth,
    required Map<String, dynamic> telemetry,
  }) {
    _logger.info(
      '[TURN_SUMMARY] Turn $turnNumber by $playerName completed',
      data: {
        'turn': turnNumber,
        'player': playerName,
        'explosions': explosions,
        'maxDepth': maxDepth,
        ...telemetry,
      },
      duration: turnDuration,
    );
  }
}
