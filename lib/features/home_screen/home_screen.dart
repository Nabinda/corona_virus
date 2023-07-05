import 'dart:developer';

import 'package:corona_virus/core/utils.dart';
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
                  // return GestureDetector(
                  //     onTap: () {
                  //       log('($row,$column)');
                  //     },
                  //     child: Text('($row,$column)'));
                  return BoardCell(
                    func: () {
                      log('$row,$column');
                      setState(() {
                        board[row][column] = VirusModel(
                            player: playerNumberTurn,
                            virusCount: Utils.increaseVirus(board[row][column]),
                            willExplode: false);
                        if (playerNumberTurn >= 4) {
                          playerNumberTurn = 1;
                        } else {
                          playerNumberTurn++;
                        }
                      });
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
