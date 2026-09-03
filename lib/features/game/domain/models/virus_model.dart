class VirusModel {
  final int virusCount;
  final int? playerId;

  const VirusModel({
    required this.virusCount,
    this.playerId,
  });

  const VirusModel.empty()
      : virusCount = 0,
        playerId = null;

  bool get isEmpty => virusCount == 0;

  bool canBePlayedBy(int activePlayerId) =>
      isEmpty || playerId == activePlayerId;

  VirusModel increment(int newPlayerId) => VirusModel(
        virusCount: virusCount + 1,
        playerId: newPlayerId,
      );

  VirusModel reset() => const VirusModel.empty();
}
