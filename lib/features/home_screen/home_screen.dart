import 'dart:developer';

import 'package:corona_virus/constants/virus_position.dart';
import 'package:corona_virus/features/components/board_cell.dart';
import 'package:corona_virus/model/player_model.dart';
import 'package:corona_virus/model/virus_model.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PlayerModel playerNumberTurn;
  late List<List<VirusModel?>> board;
  int rowCount = 8;
  int colCount = 6;
  bool isGameStarted = false;
  late List<PlayerModel> players;
  late List<PlayerModel> alivePlayer;

  @override
  void initState() {
    super.initState();
    _initalizeGame();
  }

  _initalizeGame() {
    //Adding the players when game is initialized
    players = [
      PlayerModel(id: 1, name: 'Jack'),
      PlayerModel(id: 2, name: 'Rose'),
      PlayerModel(id: 3, name: 'Romeo'),
      PlayerModel(id: 4, name: 'Juilete'),
    ];
    //TODO:: remove suffle when online mode
    players.shuffle();

    //Ordering sequence to get the player color
    int sequence = 1;
    List<PlayerModel> sequencePlayer = [];
    for (var player in players) {
      sequencePlayer.add(
          PlayerModel(id: player.id, name: player.name, sequence: sequence));

      sequence++;
    }
    alivePlayer = sequencePlayer;
    playerNumberTurn = sequencePlayer[0];
    log(alivePlayer.toString());
    //Emptying the board
    List<List<VirusModel?>> virus = List.generate(
        rowCount, (index) => List.generate(colCount, (index) => null));
    board = virus;
  }

  int getCurrentPlayerIndex() {
    final currentPlayerIndex =
        alivePlayer.indexWhere((element) => element == playerNumberTurn);
    return currentPlayerIndex;
  }

//Locate the position of virus in the board
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

//Check if the spread region is valid or not
  bool checkIfValidRegion(int row, int col) {
    log('($row,$col)');
    if (row < rowCount && row >= 0 && col >= 0 && col < colCount) {
      return true;
    } else {
      return false;
    }
  }

  //Spread the virus when condition meets
  spreadVirus(int row, int col, PlayerModel playerId) {
    log('Spread $playerId');
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

  //Check if virus is ready to spread
  //This is used for animation of components
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

  //Validate and place the virus in board
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

  //Update the player turn or declare winner
  changePlayerTurn() {
    //Logic to remove player if no more available
    if (isGameStarted) {
      List<PlayerModel> toRemove = [];
      for (var player in alivePlayer) {
        bool doesExists =
            board.any((row) => row.any((element) => element?.player == player));
        if (!doesExists) {
          toRemove.add(player);
        }
      }
      log('Alive Players: $alivePlayer');
      log('To Remove Players: $toRemove');
      alivePlayer.removeWhere((element) => toRemove.contains(element));
    }
    //Changing the player turn now
    //Check the alive player count
    //If alive player length is 1 then is declared as winner
    //Else change the turn
    if (alivePlayer.length > 1) {
      final currentPlayerIndex = getCurrentPlayerIndex();
      if (currentPlayerIndex < (alivePlayer.length - 1)) {
        playerNumberTurn = alivePlayer[currentPlayerIndex + 1];
      } else {
        //Once everyone gets there turn then the game is officially started
        if (!isGameStarted) {
          isGameStarted = true;
        }
        playerNumberTurn = alivePlayer[0];
      }
    } else {
      log('${alivePlayer[0].name} won the game');
    }
  }

  //Update the data in game board
  update(int row, int col, {PlayerModel? newPlayer}) {
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

//Handle the user tap on board
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
          Text("${playerNumberTurn.name}'s Turn "),
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
