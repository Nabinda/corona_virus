//Check if the spread region is valid or not
import 'dart:developer';

bool checkIfValidRegion(int row, int col) {
  int rowCount = 8;
  int colCount = 6;
  log('($row,$col)');
  if (row < rowCount && row >= 0 && col >= 0 && col < colCount) {
    return true;
  } else {
    return false;
  }
}
