import 'package:corona_virus/features/game/presentation/widgets/virus_view.dart';
import 'package:flutter/material.dart';
import '../../domain/models/virus_model.dart';

class BoardCell extends StatelessWidget {
  final VirusModel cell;
  final bool isCritical; // is virus about to show its reactions
  final VoidCallback onTap;
  final bool hideVirus;
  const BoardCell(
      {super.key,
      required this.cell,
      required this.isCritical,
      required this.onTap,
      required this.hideVirus});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12, width: 0.5),
          ),
          padding: const EdgeInsets.all(4.0),
          child: hideVirus
              ? const SizedBox.shrink()
              : VirusView(
                  virus: cell,
                  isCritical: isCritical,
                )),
    );
  }
}
