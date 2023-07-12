//Handle the user tap on board
import 'package:corona_virus/screens/home_screen/widgets/change_player_turn.dart';
import 'package:corona_virus/screens/home_screen/widgets/update.dart';
import 'package:corona_virus/model/player_model.dart';
import 'package:corona_virus/model/virus_model.dart';
import 'package:flutter/material.dart';

rawLogic(
    {required int row,
    required int col,
    required PlayerModel playerTurn,
    required ValueNotifier<PlayerModel> playerNumberTurn,
    required bool gameStarted,
    required ValueNotifier<bool> isGameStarted,
    required List<List<VirusModel?>> board,
    required List<PlayerModel> alivePlayer}) {
  if (board[row][col]?.player == null) {
    update(
      row,
      col,
      playerTurn: playerTurn,
      gameStarted: gameStarted,
      board: board,
    );
    changePlayerTurn(
      playerNumberTurn: playerNumberTurn,
      playerTurn: playerTurn,
      isGameStarted: isGameStarted,
      gameStarted: gameStarted,
      board: board,
      alivePlayer: alivePlayer,
    );
  } else if (board[row][col]?.player == playerTurn) {
    update(
      row,
      col,
      playerTurn: playerTurn,
      gameStarted: gameStarted,
      board: board,
    );
    changePlayerTurn(
      playerNumberTurn: playerNumberTurn,
      playerTurn: playerTurn,
      isGameStarted: isGameStarted,
      gameStarted: gameStarted,
      board: board,
      alivePlayer: alivePlayer,
    );
  }
}
