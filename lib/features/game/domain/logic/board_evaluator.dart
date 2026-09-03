import '../models/board.dart';
import '../models/position.dart';
import '../models/virus_model.dart';

class BoardEvaluator {
  final int rows;
  final int cols;

  const BoardEvaluator({required this.rows, required this.cols});

  /// Critical mass is equal to the number of orthogonal neighbors.
  int getCriticalMass(Position pos) {
    int neighbors = 0;
    if (pos.row > 0) neighbors++;
    if (pos.row < rows - 1) neighbors++;
    if (pos.col > 0) neighbors++;
    if (pos.col < cols - 1) neighbors++;
    return neighbors;
  }

  /// Checks if adding a virus triggers an explosion.
  bool isAboutToExplode(Position pos, VirusModel cell) {
    if (cell.isEmpty) return false;
    return (cell.virusCount + 1) >= getCriticalMass(pos);
  }

  /// Move is valid if within bounds and cell is empty or owned by active player.
  bool isValidMove({
    required Board board,
    required Position target,
    required int playerId,
  }) {
    if (!board.isValidPosition(target)) return false;
    final cell = board.getAt(target);
    return cell.canBePlayedBy(playerId);
  }

  /// Returns valid orthogonal neighbor positions.
  List<Position> getNeighbors(Position pos) {
    final neighbors = <Position>[];
    final deltas = const [
      [-1, 0], // North
      [1, 0], // South
      [0, -1], // West
      [0, 1], // East
    ];

    for (final d in deltas) {
      final neighbor = Position(pos.row + d[0], pos.col + d[1]);
      if (neighbor.row >= 0 &&
          neighbor.row < rows &&
          neighbor.col >= 0 &&
          neighbor.col < cols) {
        neighbors.add(neighbor);
      }
    }
    return neighbors;
  }
}
