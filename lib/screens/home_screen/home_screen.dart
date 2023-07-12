import 'dart:developer';
import 'package:corona_virus/utils/utils.dart';
import 'package:corona_virus/screens/home_screen/widgets/board_cell.dart';
import 'package:corona_virus/screens/home_screen/widgets/raw_logic.dart';
import 'package:corona_virus/model/player_model.dart';
import 'package:corona_virus/model/virus_model.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Current turn of player
  late ValueNotifier<PlayerModel> playerNumberTurn;
  //Main board
  late List<List<VirusModel?>> board;

  int rowCount = 8;
  int colCount = 6;
  ValueNotifier<bool> isGameStarted = ValueNotifier<bool>(false);
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
    playerNumberTurn = ValueNotifier<PlayerModel>(sequencePlayer[0]);
    log(alivePlayer.toString());
    //Emptying the board
    List<List<VirusModel?>> virus = List.generate(
        rowCount, (index) => List.generate(colCount, (index) => null));
    board = virus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<PlayerModel>(
          valueListenable: playerNumberTurn,
          builder:
              (BuildContext context, PlayerModel playerTurn, Widget? child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("${playerTurn.name}'s Turn "),
                    const SizedBox(width: 10),
                    Container(
                      height: 15,
                      width: 15,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Utils.getPlayerColor(playerTurn.sequence)),
                    )
                  ],
                ),
                Container(
                  decoration: BoxDecoration(border: Border.all()),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: GridView.builder(
                      itemCount: 6 * 8,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6),
                      itemBuilder: (context, index) {
                        int row = index ~/ 6;
                        int column = index % 6;

                        return ValueListenableBuilder<bool>(
                            valueListenable: isGameStarted,
                            builder: (context, bool gameStarted, child) {
                              return BoardCell(
                                func: () {
                                  rawLogic(
                                      row: row,
                                      col: column,
                                      playerTurn: playerTurn,
                                      playerNumberTurn: playerNumberTurn,
                                      isGameStarted: isGameStarted,
                                      gameStarted: gameStarted,
                                      board: board,
                                      alivePlayer: alivePlayer);
                                },
                                virus: board[row][column],
                              );
                            });
                      },
                    ),
                  ),
                )
              ],
            );
          }),
    );
  }
}
