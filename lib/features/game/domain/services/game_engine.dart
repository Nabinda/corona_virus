import '../events/game_events.dart';
import '../events/game_log_context.dart';
import '../logic/board_evaluator.dart';
import '../logic/reaction_simulator.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../models/position.dart';

class GameEngineResult {
  final GameState state;
  final List<GameEvent> events;

  const GameEngineResult({
    required this.state,
    required this.events,
  });
}

class GameEngine {
  final BoardEvaluator evaluator;
  final ReactionSimulator simulator;

  const GameEngine({
    required this.evaluator,
    required this.simulator,
  });

  GameEngineResult executeTurn({
    required GameState state,
    required Position target,
    required String gameId,
    required DateTime matchStartTime,
  }) {
    final activePlayer = state.currentPlayer;
    final events = <GameEvent>[];
    final turnStopwatch = Stopwatch()..start();
    final context = GameLogContext(
      gameId: gameId,
      moveId: 'MOVE-${state.turnNumber}',
      turnNumber: state.turnNumber,
      playerId: activePlayer.id,
      playerName: activePlayer.name,
    );

    events.add(MoveAttempted(context, row: target.row, col: target.col));

    // 1. Move Validation
    if (!evaluator.isValidMove(
      board: state.board,
      target: target,
      playerId: activePlayer.id,
    )) {
      events.add(MoveRejected(
        context,
        row: target.row,
        col: target.col,
        reason: 'Cell is not claimable by active player',
      ));
      return GameEngineResult(state: state, events: events);
    }

    events.add(MoveAccepted(context, row: target.row, col: target.col));

    // 2. Reaction Simulation with scoped reactionId
    final stopwatch = Stopwatch()..start();
    final simulation = simulator.simulate(
      board: state.board,
      target: target,
      playerId: activePlayer.id,
      context: context.withReaction('RX-${state.turnNumber}'),
    );
    stopwatch.stop();

    events.addAll(simulation.events);

    if (simulation.totalExplosions > 0) {
      events.add(ReactionChainCompleted(
        context,
        duration: stopwatch.elapsed,
        maxChainDepth: simulation.maxChainDepth,
        totalExplosions: simulation.totalExplosions,
        totalSpreads: simulation.totalSpreads,
      ));
    }

    // 3. Mark First Turn & Process Eliminations
    var updatedPlayers = List<PlayerModel>.from(state.players);
    updatedPlayers[state.currentPlayerIndex] =
        activePlayer.markFirstTurnCompleted();

    final livingPlayerCellCounts = <int, int>{
      for (final p in updatedPlayers)
        if (p.isAlive) p.id: 0
    };

    for (final row in simulation.updatedBoard.cells) {
      for (final cell in row) {
        if (!cell.isEmpty &&
            livingPlayerCellCounts.containsKey(cell.playerId)) {
          livingPlayerCellCounts[cell.playerId!] =
              livingPlayerCellCounts[cell.playerId!]! + 1;
        }
      }
    }

    for (int i = 0; i < updatedPlayers.length; i++) {
      final p = updatedPlayers[i];
      if (p.isAlive &&
          p.hasTakenFirstTurn &&
          (livingPlayerCellCounts[p.id] ?? 0) == 0) {
        updatedPlayers[i] = p.markEliminated();
        final remaining =
            updatedPlayers.where((player) => player.isAlive).length;
        events.add(PlayerEliminated(
          context,
          eliminatedPlayerId: p.id,
          eliminatedPlayerName: p.name,
          remainingPlayers: remaining,
        ));
      }
    }

    // 4. Win Condition
    final alivePlayers = updatedPlayers.where((p) => p.isAlive).toList();
    final allPlayersHadTurn = updatedPlayers.every((p) => p.hasTakenFirstTurn);

    if (allPlayersHadTurn && alivePlayers.length == 1) {
      final winner = alivePlayers.first;
      events.add(GameFinished(
        context,
        winnerPlayerId: winner.id,
        winnerPlayerName: winner.name,
        matchDuration: DateTime.now().difference(matchStartTime),
      ));
      turnStopwatch.stop();
      events.add(TurnEnded(context, duration: turnStopwatch.elapsed));
      return GameEngineResult(
        state: state.copyWith(
          board: simulation.updatedBoard,
          players: updatedPlayers,
          isGameOver: true,
          winnerPlayerId: winner.id,
        ),
        events: events,
      );
    }

    // 5. Turn Rotation
    int nextIndex = (state.currentPlayerIndex + 1) % updatedPlayers.length;
    int loopSafetyCounter = 0;
    while (!updatedPlayers[nextIndex].isAlive &&
        loopSafetyCounter < updatedPlayers.length) {
      nextIndex = (nextIndex + 1) % updatedPlayers.length;
      loopSafetyCounter++;
    }
    turnStopwatch.stop();
    events.add(TurnEnded(context, duration: stopwatch.elapsed));

    return GameEngineResult(
      state: state.copyWith(
        board: simulation.updatedBoard,
        players: updatedPlayers,
        currentPlayerIndex: nextIndex,
        turnNumber: state.turnNumber + 1,
      ),
      events: events,
    );
  }
}
