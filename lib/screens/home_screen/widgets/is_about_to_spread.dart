//Check if virus is ready to spread
//This is used for animation of components
import 'package:corona_virus/constants/virus_position.dart';
import 'package:corona_virus/screens/home_screen/widgets/get_virus_position.dart';

bool isAboutToSpread(int row, int col, int updatedVirus) {
  VirusPosition currentPosition = getVirusPosition(row, col);

  if (currentPosition == VirusPosition.corner && updatedVirus == 1) {
    return true;
  } else if (currentPosition == VirusPosition.edge && updatedVirus == 2) {
    return true;
  } else if (currentPosition == VirusPosition.others && updatedVirus == 3) {
    return true;
  } else {
    return false;
  }
}
