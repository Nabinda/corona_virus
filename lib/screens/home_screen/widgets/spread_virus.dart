//Spread the virus when condition meets
import 'dart:developer';
import 'package:corona_virus/screens/home_screen/widgets/check_if_valid_region.dart';
import 'package:corona_virus/screens/home_screen/widgets/update.dart';
import 'package:corona_virus/model/player_model.dart';
import 'package:corona_virus/model/virus_model.dart';

spreadVirus(
    {required int row,
    required int col,
    required PlayerModel playerId,
    required bool gameStarted,
    required List<List<VirusModel?>> board}) {
  log('Spread $playerId');
  //For X-Axis Spread (row)
  //Y variable stays constant(col)
  bool canSpreadLeft = checkIfValidRegion(row - 1, col);
  bool canSpreadRight = checkIfValidRegion(row + 1, col);
  //For Y-Axis Spread
  //X variable stays constant(row)
  bool canSpreadTop = checkIfValidRegion(row, col + 1);
  bool canSpreadBottom = checkIfValidRegion(row, col - 1);
  //TODO:: Update the animation Here

  if (canSpreadRight) {
    update(row + 1, col,
        newPlayer: playerId,
        playerTurn: playerId,
        gameStarted: gameStarted,
        board: board);
  }
  if (canSpreadLeft) {
    update(row - 1, col,
        newPlayer: playerId,
        playerTurn: playerId,
        gameStarted: gameStarted,
        board: board);
  }
  if (canSpreadTop) {
    update(row, col + 1,
        newPlayer: playerId,
        playerTurn: playerId,
        gameStarted: gameStarted,
        board: board);
  }
  if (canSpreadBottom) {
    update(row, col - 1,
        newPlayer: playerId,
        playerTurn: playerId,
        gameStarted: gameStarted,
        board: board);
  }
}
