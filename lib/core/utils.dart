import 'package:corona_virus/constants/app_icon_constants.dart';
import 'package:corona_virus/constants/player_colors.dart';
import 'package:corona_virus/model/virus_model.dart';
import 'package:flutter/material.dart';

class Utils {
  static Color getPlayerColor(int? player) {
    switch (player) {
      case 1:
        return PlayerColors.player1;
      case 2:
        return PlayerColors.player2;
      case 3:
        return PlayerColors.player3;
      case 4:
        return PlayerColors.player4;
      default:
        return PlayerColors.player4;
    }
  }

  static int increaseVirus(VirusModel? virus) {
    if (virus?.willExplode ?? false) {
      return 0;
    }
    if ((virus?.virusCount ?? 0) < 3) {
      return (virus?.virusCount ?? 0) + 1;
    }
    return 1;
  }

  static Widget? getPlayerVirus(VirusModel? virus) {
    if (virus != null) {
      if (virus.virusCount == 3) {
        return Image.asset(
          AppIconConstants.corona3,
          color: getPlayerColor(virus.player?.sequence),
        );
      }
      if (virus.virusCount == 2 && (virus.willExplode ?? false)) {
        return Image.asset(
          AppIconConstants.corona2fast,
          color: getPlayerColor(virus.player?.sequence),
        );
      }
      if (virus.virusCount == 2 && !(virus.willExplode ?? true)) {
        return Image.asset(
          AppIconConstants.corona2slow,
          color: getPlayerColor(virus.player?.sequence),
        );
      }
      if (virus.virusCount == 1 && !(virus.willExplode ?? true)) {
        return Image.asset(
          AppIconConstants.corona1slow,
          color: getPlayerColor(virus.player?.sequence),
        );
      }
      if (virus.virusCount == 1 && (virus.willExplode ?? false)) {
        return Image.asset(
          AppIconConstants.corona1fast,
          color: getPlayerColor(virus.player?.sequence),
        );
      }
    }
    return Container();
  }
}
