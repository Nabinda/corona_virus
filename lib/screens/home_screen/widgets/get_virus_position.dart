//Locate the position of virus in the board
import 'package:corona_virus/constants/virus_position.dart';

VirusPosition getVirusPosition(int row, int col) {
  int rowCount = 8;
  int colCount = 6;
  if (row == 0 && col == 0 ||
      row == 0 && col == colCount - 1 ||
      row == rowCount - 1 && col == 0 ||
      row == rowCount - 1 && col == colCount - 1) {
    return VirusPosition.corner;
  } else if (row == 0 ||
      row == rowCount - 1 ||
      col == 0 ||
      col == colCount - 1) {
    return VirusPosition.edge;
  } else {
    return VirusPosition.others;
  }
}
