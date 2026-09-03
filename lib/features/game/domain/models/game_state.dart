import 'board.dart';
import 'player_model.dart';

class GameState {
  final Board board;
  final List<PlayerModel> players;
  final int currentPlayerIndex;
  final int turnNumber;
  final bool isGameOver;
  final int? winnerPlayerId;

  const GameState({
    required this.board,
    required this.players,
    required this.currentPlayerIndex,
    required this.turnNumber,
    required this.isGameOver,
    this.winnerPlayerId,
  });

  PlayerModel get currentPlayer => players[currentPlayerIndex];

  GameState copyWith({
    Board? board,
    List<PlayerModel>? players,
    int? currentPlayerIndex,
    int? turnNumber,
    bool? isGameOver,
    int? winnerPlayerId,
  }) {
    return GameState(
      board: board ?? this.board,
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      turnNumber: turnNumber ?? this.turnNumber,
      isGameOver: isGameOver ?? this.isGameOver,
      winnerPlayerId: winnerPlayerId ?? this.winnerPlayerId,
    );
  }
}
