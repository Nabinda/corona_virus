class GameLogContext {
  final String gameId;
  final String moveId;
  final int turnNumber;
  final int playerId;
  final String playerName;
  final String? reactionId;

  const GameLogContext({
    required this.gameId,
    required this.moveId,
    required this.turnNumber,
    required this.playerId,
    required this.playerName,
    this.reactionId,
  });

  GameLogContext withReaction(String reactionId) => GameLogContext(
        gameId: gameId,
        moveId: moveId,
        turnNumber: turnNumber,
        playerId: playerId,
        playerName: playerName,
        reactionId: reactionId,
      );

  Map<String, dynamic> toMap() => {
        'gameId': gameId,
        'moveId': moveId,
        'turnNumber': turnNumber,
        'playerId': playerId,
        'playerName': playerName,
        if (reactionId != null) 'reactionId': reactionId,
      };
}
