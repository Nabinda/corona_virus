//Validate and place the virus in board
import 'package:corona_virus/constants/virus_position.dart';
import 'package:corona_virus/screens/home_screen/widgets/get_virus_position.dart';
import 'package:corona_virus/model/virus_model.dart';

int increaseVirusLogic(int row, int col, List<List<VirusModel?>> board) {
  int previousVirusCount = board[row][col]?.virusCount ?? 0;
  VirusPosition virusPosition = getVirusPosition(row, col);
  if (virusPosition == VirusPosition.corner) {
    if (previousVirusCount < 1) {
      return 1;
    } else {
      return 0;
    }
  } else if (virusPosition == VirusPosition.edge) {
    if (previousVirusCount < 2) {
      return previousVirusCount + 1;
    } else {
      return 0;
    }
  } else {
    if (previousVirusCount < 3) {
      return previousVirusCount + 1;
    } else {
      return 0;
    }
  }
}
