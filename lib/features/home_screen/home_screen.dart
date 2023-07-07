import 'dart:developer';

import 'package:corona_virus/constants/virus_position.dart';
import 'package:corona_virus/features/components/board_cell.dart';
import 'package:corona_virus/model/virus_model.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int playerNumberTurn;
  late List<List<VirusModel?>> board;
  int rowCount = 8;
  int colCount = 6;
  bool isGameStarted = false;

  @override
  void initState() {
    super.initState();
    _initalizeGame();
  }

  _initalizeGame() {
    playerNumberTurn = 1;
    List<List<VirusModel?>> virus = List.generate(
        rowCount, (index) => List.generate(colCount, (index) => null));
    board = virus;
  }

  VirusPosition getVirusPosition(int row, int col) {
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

  bool checkIfValidRegion(int row, int col) {
    log('($row,$col)');
    if (row < rowCount && row >= 0 && col >= 0 && col < colCount) {
      return true;
    } else {
      return false;
    }
  }

  spreadVirus(int row, int col, int playerId) {
    //For X-Axis Spread (row)
    //Y variable stays constant(col)
    bool canSpreadLeft = checkIfValidRegion(row - 1, col);
    bool canSpreadRight = checkIfValidRegion(row + 1, col);
    //For Y-Axis Spread
    //X variable stays constant(row)
    bool canSpreadTop = checkIfValidRegion(row, col + 1);
    bool canSpreadBottom = checkIfValidRegion(row, col - 1);
    //TODO:: Update the animation Here
    if (canSpreadRight) {
      update(row + 1, col, newPlayer: playerId);
    }
    if (canSpreadLeft) {
      update(row - 1, col, newPlayer: playerId);
    }
    if (canSpreadTop) {
      update(row, col + 1, newPlayer: playerId);
    }
    if (canSpreadBottom) {
      update(row, col - 1, newPlayer: playerId);
    }
  }

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

  int increaseVirusLogic(int row, int col) {
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

  changePlayerTurn() {
    if (playerNumberTurn >= 4) {
      isGameStarted = true;
      playerNumberTurn = 1;
    } else {
      playerNumberTurn++;
    }
  }

  update(int row, int col, {int? newPlayer}) {
    int increaseVirusCount = increaseVirusLogic(row, col);
    setState(() {
      if (increaseVirusCount == 0 && isGameStarted) {
        board[row][col] = null;
        spreadVirus(row, col, playerNumberTurn);
      } else {
        board[row][col] = VirusModel(
            player: newPlayer ?? playerNumberTurn,
            virusCount: increaseVirusCount,
            willExplode: isAboutToSpread(row, col, increaseVirusCount));
      }
    });
  }

  rawLogic(int row, int col) {
    if (board[row][col]?.player == null) {
      update(row, col);
      changePlayerTurn();
    } else if (board[row][col]?.player == playerNumberTurn) {
      update(row, col);
      changePlayerTurn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Player Turn: $playerNumberTurn "),
          Container(
            decoration: BoxDecoration(border: Border.all()),
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: GridView.builder(
                itemCount: 6 * 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6),
                itemBuilder: (context, index) {
                  int row = index ~/ 6;
                  int column = index % 6;
                  // return Center(
                  //     child: Text(getVirusPosition(row, column).toString()));

                  return BoardCell(
                    func: () {
                      rawLogic(row, column);
                    },
                    virus: board[row][column],
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
