import 'package:corona_virus/features/game/domain/events/game_events.dart';
import 'package:flutter/material.dart';
import '../../../../core/logger/sinks/telemetry_sink.dart';
import '../../domain/models/board.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player_model.dart';
import '../../domain/models/position.dart';
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

  GameController({
    required GameEngine engine,
    required GameLoggerAdapter loggerAdapter,
    required int rows,
    required int cols,
    required List<PlayerModel> players,
    String? gameId,
    this.onPlayerEliminated,
    this.onGameFinished,
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

  GameState get state => _state;
  Board get board => _state.board;
  PlayerModel get currentPlayer => _state.currentPlayer;
  bool get isGameOver => _state.isGameOver;
  int get turnNumber => _state.turnNumber;

  void onCellTapped(int row, int col) async {
    if (_state.isGameOver) return;

    final result = _engine.executeTurn(
      state: _state,
      target: Position(row, col),
      gameId: gameId,
      matchStartTime: _matchStartTime,
    );

    _loggerAdapter.handleEvents(result.events);
    // Check for elimination events and dispatch callback
    // Dispatch lifecycle callbacks
    for (final event in result.events) {
      if (event is PlayerEliminated) {
        onPlayerEliminated?.call(event);
      } else if (event is GameFinished) {
        await TelemetrySink.instance.exportSessionLogs();
        onGameFinished?.call(event);
      }
    }
    _state = result.state;

    notifyListeners();
  }
}
