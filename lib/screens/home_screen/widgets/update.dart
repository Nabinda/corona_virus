//Update the data in game board
import 'package:corona_virus/screens/home_screen/widgets/increase_virus_logic.dart';
import 'package:corona_virus/screens/home_screen/widgets/is_about_to_spread.dart';
import 'package:corona_virus/screens/home_screen/widgets/spread_virus.dart';
import 'package:corona_virus/model/player_model.dart';
import 'package:corona_virus/model/virus_model.dart';

update(int row, int col,
    {PlayerModel? newPlayer,
    required PlayerModel playerTurn,
    required bool gameStarted,
    required List<List<VirusModel?>> board}) {
  int increaseVirusCount = increaseVirusLogic(row, col, board);
  if (increaseVirusCount == 0 && gameStarted) {
    board[row][col] = null;
    spreadVirus(
        row: row,
        col: col,
        playerId: playerTurn,
        gameStarted: gameStarted,
        board: board);
  } else {
    board[row][col] = VirusModel(
        player: newPlayer ?? playerTurn,
        virusCount: increaseVirusCount,
        willExplode: isAboutToSpread(row, col, increaseVirusCount));
  }
}
