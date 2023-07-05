import 'package:corona_virus/core/utils.dart';
import 'package:corona_virus/model/virus_model.dart';
import 'package:flutter/material.dart';

class BoardCell extends StatelessWidget {
  const BoardCell({super.key, required this.func, required this.virus});
  final Function() func;
  final VirusModel? virus;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: func,
      child: Container(
        decoration: BoxDecoration(border: Border.all(width: 1)),
        child: Utils.getPlayerVirus(virus),
      ),
    );
  }
}
