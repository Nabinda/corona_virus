import 'package:corona_virus/core/logger/sinks/telemetry_sink.dart';
import 'package:flutter/material.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../core/logger/sinks/console_log_sink.dart';
import '../../../../themes/player_colors.dart';
import '../domain/events/game_events.dart';
import '../domain/logic/board_evaluator.dart';
import '../domain/logic/reaction_simulator.dart';
import '../domain/models/player_model.dart';
import '../domain/models/position.dart';
import '../domain/services/game_engine.dart';
import '../domain/services/game_logger_adapter.dart';
import 'controllers/game_controller.dart';
import 'widgets/board_cell.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int _rows = 8;
  static const int _cols = 6;

  late final BoardEvaluator _evaluator;
  late final GameEngine _engine;
  late final GameLoggerAdapter _loggerAdapter;
  late GameController _controller;

  @override
  void initState() {
    super.initState();
    _evaluator = const BoardEvaluator(rows: _rows, cols: _cols);
    final simulator = ReactionSimulator(_evaluator);
    _engine = GameEngine(evaluator: _evaluator, simulator: simulator);

    final logger = AppLogger([ConsoleLogSink(), TelemetrySink.instance]);
    _loggerAdapter = GameLoggerAdapter(logger);

    _initNewGame();
  }

  void _initNewGame() {
    _controller = GameController(
      engine: _engine,
      loggerAdapter: _loggerAdapter,
      rows: _rows,
      cols: _cols,
      players: [
        PlayerModel.create(id: 1, name: 'Red'),
        PlayerModel.create(id: 2, name: 'Green'),
        PlayerModel.create(id: 3, name: 'Randi'),
        PlayerModel.create(id: 4, name: 'Muji'),
      ],
      onPlayerEliminated: _handleElimination,
      onGameFinished: _handleGameFinished,
    );
  }

  void _handleElimination(PlayerEliminated event) {
    if (!mounted) return;

    final eliminatedColor = PlayerColors.fromIndex(event.eliminatedPlayerId);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E1E26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
              color: eliminatedColor.withValues(alpha: 0.6), width: 1.5),
        ),
        content: Row(
          children: [
            Icon(Icons.dangerous_rounded, color: eliminatedColor, size: 20),
            const SizedBox(width: 10),
            Text(
              '${event.eliminatedPlayerName} has been eliminated!',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGameFinished(GameFinished event) {
    if (!mounted) return;

    final winnerColor = PlayerColors.fromIndex(event.winnerPlayerId);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E1E26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side:
              BorderSide(color: winnerColor.withValues(alpha: 0.6), width: 1.5),
        ),
        content: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: winnerColor..withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: winnerColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${event.winnerPlayerName} is Victorious!',
                style: TextStyle(
                  color: winnerColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: winnerColor,
                  foregroundColor: Colors.black,
                ),
                onPressed: _restartGame,
                child: const Text('Play Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _controller.dispose();
      _initNewGame();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final activePlayer = _controller.currentPlayer;
        final activeColor = PlayerColors.fromIndex(activePlayer.id);

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D11),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: activeColor..withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _controller.isGameOver
                      ? '${activePlayer.name} Won!'
                      : "${activePlayer.name}'s Turn",
                  style: TextStyle(
                    color: activeColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Restart Match',
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                onPressed: _restartGame,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Top status bar with turn count
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Turn ${_controller.turnNumber}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 13),
                      ),
                      Text(
                        '${_rows}x$_cols Grid',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // Main Game Board
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: AspectRatio(
                        aspectRatio: _cols / _rows,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _rows * _cols,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _cols,
                          ),
                          itemBuilder: (context, index) {
                            final r = index ~/ _cols;
                            final c = index % _cols;
                            final pos = Position(r, c);
                            final cell = _controller.board.getAt(pos);

                            return BoardCell(
                              cell: cell,
                              isCritical: !cell.isEmpty &&
                                  _evaluator.isAboutToExplode(pos, cell),
                              cellColor: cell.playerId != null
                                  ? PlayerColors.fromIndex(cell.playerId!)
                                  : null,
                              onTap: () => _controller.onCellTapped(r, c),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
