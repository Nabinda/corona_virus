import '../../domain/models/board.dart';
import 'reaction_timeline.dart';

class ReactionCellState {
  final int row;
  final int col;
  final int virusCount;
  final int? playerId;
  const ReactionCellState({
    required this.row,
    required this.col,
    required this.virusCount,
    required this.playerId,
  });

  ReactionCellState copyWith({
    int? virusCount,
    int? playerId,
  }) {
    return ReactionCellState(
      row: row,
      col: col,
      virusCount: virusCount ?? this.virusCount,
      playerId: playerId ?? this.playerId,
    );
  }
}

class ReactionBoardState {
  final List<ReactionCellState> cells;

  const ReactionBoardState({
    required this.cells,
  });

  bool get isEmpty => cells.isEmpty;

  ReactionCellState? cellAt(int row, int col) {
    for (final cell in cells) {
      if (cell.row == row && cell.col == col) {
        return cell;
      }
    }

    return null;
  }

  factory ReactionBoardState.fromBoard(Board board) {
    final cells = <ReactionCellState>[];

    for (var row = 0; row < board.rows; row++) {
      for (var col = 0; col < board.cols; col++) {
        final virus = board.cells[row][col];

        cells.add(
          ReactionCellState(
            row: row,
            col: col,
            virusCount: virus.virusCount,
            playerId: virus.playerId,
          ),
        );
      }
    }

    return ReactionBoardState(
      cells: List.unmodifiable(cells),
    );
  }
  ReactionBoardState applyWave(ReactionWave wave) {
    final updatedCells = List<ReactionCellState>.from(cells);

    for (final update in wave.stateUpdates) {
      final index = updatedCells.indexWhere(
        (cell) => cell.row == update.row && cell.col == update.col,
      );

      final newCell = ReactionCellState(
        row: update.row,
        col: update.col,
        virusCount: update.virusCount,
        playerId: update.playerId,
      );

      if (index == -1) {
        updatedCells.add(newCell);
      } else {
        updatedCells[index] = newCell;
      }
    }

    return ReactionBoardState(
      cells: List.unmodifiable(updatedCells),
    );
  }
}
