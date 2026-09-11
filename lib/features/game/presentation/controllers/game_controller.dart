import 'package:corona_virus/features/game/domain/events/game_events.dart';
import 'package:flutter/material.dart';
import '../../../../core/logger/sinks/telemetry_sink.dart';
import '../../domain/models/board.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player_model.dart';
import '../../domain/models/position.dart';
import '../../domain/models/virus_model.dart';
import '../../domain/services/game_engine.dart';
import '../../domain/services/game_logger_adapter.dart';

class GameController extends ChangeNotifier {
  final GameEngine _engine;
  final GameLoggerAdapter _loggerAdapter;
  final String gameId;
  final DateTime _matchStartTime;

  late GameState _state;
  void Function(PlayerEliminated event)? onPlayerEliminated;
  void Function(GameFinished event)? onGameFinished;
  Future<void> Function(List<GameEvent> events)? onReactionAnimation;

  GameController({
    required GameEngine engine,
    required GameLoggerAdapter loggerAdapter,
    required int rows,
    required int cols,
    required List<PlayerModel> players,
    String? gameId,
    this.onPlayerEliminated,
    this.onGameFinished,
    this.onReactionAnimation,
  })  : _engine = engine,
        _loggerAdapter = loggerAdapter,
        gameId = gameId ?? 'GAME-${DateTime.now().millisecondsSinceEpoch}',
        _matchStartTime = DateTime.now() {
    _state = GameState(
      board: Board(rows: rows, cols: cols),
      players: players,
      currentPlayerIndex: 0,
      turnNumber: 1,
      isGameOver: false,
    );
  }
  Board? _displayBoard;
  GameState get state => _state;
  Board get board => _displayBoard ?? _state.board;
  PlayerModel get currentPlayer => _state.currentPlayer;
  bool get isGameOver => _state.isGameOver;
  int get turnNumber => _state.turnNumber;
  bool _isProcessingTurn = false;

  Future<void> onCellTapped(int row, int col) async {
    if (_state.isGameOver || _isProcessingTurn) return;

    _isProcessingTurn = true;

    try {
      final result = _engine.executeTurn(
        state: _state,
        target: Position(row, col),
        gameId: gameId,
        matchStartTime: _matchStartTime,
      );

      final hasReaction = result.events.any(
        (event) => event is VirusSpread,
      );

      if (!hasReaction) {
        _state = result.state;
        notifyListeners();

        _loggerAdapter.handleEvents(result.events);

        for (final event in result.events) {
          if (event is PlayerEliminated) {
            onPlayerEliminated?.call(event);
          } else if (event is GameFinished) {
            await TelemetrySink.instance.exportSessionLogs();
            onGameFinished?.call(event);
          }
        }

        return;
      }

      // ---------------------------------------------------------
      // Start with a copy of the current board.
      // ---------------------------------------------------------

      _displayBoard = _state.board.copy();

      notifyListeners();

      // ---------------------------------------------------------
      // Let GameScreen play the reaction animation.
      // The controller will be updated after every depth.
      // ---------------------------------------------------------

      if (onReactionAnimation != null) {
        await onReactionAnimation!(result.events);
      }

      // ---------------------------------------------------------
      // Animation is finished.
      // Commit the real final state.
      // ---------------------------------------------------------

      _state = result.state;
      _displayBoard = null;

      _loggerAdapter.handleEvents(result.events);

      for (final event in result.events) {
        if (event is PlayerEliminated) {
          onPlayerEliminated?.call(event);
        } else if (event is GameFinished) {
          await TelemetrySink.instance.exportSessionLogs();
          onGameFinished?.call(event);
        }
      }

      notifyListeners();
    } finally {
      _displayBoard = null;
      _isProcessingTurn = false;
    }
  }

  void applyAnimationUpdates(
    List<CellUpdated> updates,
  ) {
    if (_displayBoard == null) return;

    for (final update in updates) {
      _displayBoard!.setAt(
        Position(
          update.row,
          update.col,
        ),
        VirusModel(
          virusCount: update.virusCount,
          playerId: update.playerId,
        ),
      );
    }

    notifyListeners();
  }
}
