//Update the player turn or declare winner
import 'dart:developer';
import 'package:corona_virus/screens/home_screen/widgets/get_current_player_index.dart';
import 'package:corona_virus/model/player_model.dart';
import 'package:corona_virus/model/virus_model.dart';
import 'package:flutter/material.dart';

changePlayerTurn(
    {required ValueNotifier<PlayerModel> playerNumberTurn,
    required PlayerModel playerTurn,
    required bool gameStarted,
    required ValueNotifier<bool> isGameStarted,
    required List<List<VirusModel?>> board,
    required List<PlayerModel> alivePlayer}) {
  //Logic to remove player if no more available
  if (gameStarted) {
    //Out vako player
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
    final currentPlayerIndex = getCurrentPlayerIndex(playerTurn, alivePlayer);
    if (currentPlayerIndex < (alivePlayer.length - 1)) {
      playerNumberTurn.value = alivePlayer[currentPlayerIndex + 1];
    } else {
      //Once everyone gets there turn then the game is officially started
      if (!gameStarted) {
        isGameStarted.value = true;
      }
      playerNumberTurn.value = alivePlayer[0];
    }
  } else {
    log('${alivePlayer[0].name} won the game');
  }
}
