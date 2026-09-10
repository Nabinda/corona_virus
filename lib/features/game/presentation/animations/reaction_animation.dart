import '../../domain/events/game_events.dart';

enum ReactionAnimationType {
  explosion,
  spread,
}

enum ReactionDirection {
  up,
  down,
  left,
  right,
}

class ReactionAnimation {
  final ReactionAnimationType type;

  final int row;
  final int col;

  /// Only used by spread animations.
  final int? toRow;
  final int? toCol;
  final int playerId;
  final int chainDepth;

  const ReactionAnimation({
    required this.type,
    required this.row,
    required this.col,
    this.toRow,
    this.toCol,
    required this.chainDepth,
    required this.playerId,
  });

  ReactionDirection? get direction {
    if (!isSpread || toRow == null || toCol == null) {
      return null;
    }

    if (toRow! < row) {
      return ReactionDirection.up;
    }

    if (toRow! > row) {
      return ReactionDirection.down;
    }

    if (toCol! < col) {
      return ReactionDirection.left;
    }

    if (toCol! > col) {
      return ReactionDirection.right;
    }

    return null;
  }

  factory ReactionAnimation.fromExplosion(VirusExploded event) {
    return ReactionAnimation(
      type: ReactionAnimationType.explosion,
      row: event.row,
      col: event.col,
      chainDepth: event.chainDepth,
      playerId: event.playerId,
    );
  }

  factory ReactionAnimation.fromSpread(VirusSpread event) {
    return ReactionAnimation(
      type: ReactionAnimationType.spread,
      row: event.fromRow,
      col: event.fromCol,
      toRow: event.toRow,
      toCol: event.toCol,
      chainDepth: event.chainDepth,
      playerId: event.playerId,
    );
  }

  bool get isExplosion => type == ReactionAnimationType.explosion;

  bool get isSpread => type == ReactionAnimationType.spread;
}
