import 'position.dart';
import 'virus_model.dart';

class Board {
  final int rows;
  final int cols;
  final List<List<VirusModel>> cells;

  Board({
    required this.rows,
    required this.cols,
    List<List<VirusModel>>? cells,
  }) : cells = cells ??
            List.generate(
              rows,
              (_) => List.generate(cols, (_) => const VirusModel.empty()),
            );

  VirusModel getAt(Position pos) => cells[pos.row][pos.col];

  bool isValidPosition(Position pos) =>
      pos.row >= 0 && pos.row < rows && pos.col >= 0 && pos.col < cols;

  Board copyWithCell(Position pos, VirusModel newCell) {
    final updated = cells.map((r) => List<VirusModel>.from(r)).toList();
    updated[pos.row][pos.col] = newCell;
    return Board(rows: rows, cols: cols, cells: updated);
  }
}
