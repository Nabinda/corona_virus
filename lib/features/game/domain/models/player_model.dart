class PlayerModel {
  final int id;
  final String name;
  final bool isAlive;
  final bool hasTakenFirstTurn;

  const PlayerModel({
    required this.id,
    required this.name,
    this.isAlive = true,
    this.hasTakenFirstTurn = false,
  });

  /// Factory constructor to initialize a fresh player for a new match
  factory PlayerModel.create({
    required int id,
    required String name,
  }) {
    return PlayerModel(
      id: id,
      name: name,
      isAlive: true,
      hasTakenFirstTurn: false,
    );
  }
  PlayerModel markFirstTurnCompleted() => PlayerModel(
        id: id,
        name: name,
        isAlive: isAlive,
        hasTakenFirstTurn: true,
      );

  PlayerModel markEliminated() => PlayerModel(
        id: id,
        name: name,
        isAlive: false,
        hasTakenFirstTurn: hasTakenFirstTurn,
      );
}
