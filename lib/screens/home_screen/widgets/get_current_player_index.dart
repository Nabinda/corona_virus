import 'package:corona_virus/model/player_model.dart';

int getCurrentPlayerIndex(
    PlayerModel playerTurn, List<PlayerModel> alivePlayer) {
  final currentPlayerIndex =
      alivePlayer.indexWhere((element) => element == playerTurn);
  return currentPlayerIndex;
}
