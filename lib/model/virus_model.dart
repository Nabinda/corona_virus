import 'package:corona_virus/model/player_model.dart';

class VirusModel {
  final PlayerModel? player;
  final bool? willExplode;
  final int? virusCount;
  final int? rowPosition;
  final int? colPosition;
  VirusModel(
      {this.player,
      this.willExplode,
      this.virusCount,
      this.rowPosition,
      this.colPosition});
}
