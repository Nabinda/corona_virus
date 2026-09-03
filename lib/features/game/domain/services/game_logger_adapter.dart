import '../../../../core/logger/app_logger.dart';
import '../../../../core/logger/log_level.dart';
import '../events/game_events.dart';

class GameLoggerAdapter {
  final AppLogger _logger;

  GameLoggerAdapter(this._logger);

  void handleEvent(GameEvent event) {
    final ctx = {
      'game': event.context.gameId,
      'move': event.context.moveId,
      'turn': event.context.turnNumber,
      'player': event.context.playerName,
    };

    switch (event) {
      case TurnStarted _:
        _logger.info('TURN_STARTED', ctx);

      case MoveAttempted e:
        _logger
            .debug('MOVE_ATTEMPTED', {...ctx, 'cell': '(${e.row},${e.col})'});

      case MoveAccepted e:
        _logger.info('MOVE_ACCEPTED', {...ctx, 'cell': '(${e.row},${e.col})'});

      case MoveRejected e:
        _logger.warning('MOVE_REJECTED',
            {...ctx, 'cell': '(${e.row},${e.col})', 'reason': e.reason});

      case CellUpdated e:
        _logger.debug('CELL_UPDATED',
            {...ctx, 'cell': '(${e.row},${e.col})', 'viruses': e.virusCount});

      case ReactionStarted e:
        _logger.info('REACTION_STARTED',
            {...ctx, 'origin': '(${e.originRow},${e.originCol})'});

      case VirusExploded e:
        _logger.info('EXPLOSION',
            {...ctx, 'cell': '(${e.row},${e.col})', 'depth': e.chainDepth});

      case VirusSpread e:
        _logger.debug('VIRUS_SPREAD', {
          ...ctx,
          'from': '(${e.fromRow},${e.fromCol})',
          'to': '(${e.toRow},${e.toCol})',
          'depth': e.chainDepth,
        });

      case ReactionChainCompleted e:
        // Slow reaction warning if it took more than 100ms
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
        _logger.warning('PLAYER_ELIMINATED', {
          ...ctx,
          'eliminated': e.eliminatedPlayerName,
          'remaining': e.remainingPlayers,
        });

      case TurnEnded e:
        _logger.info('TURN_ENDED', ctx, e.duration);

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
}
