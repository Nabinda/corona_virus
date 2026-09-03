// lib/features/game/presentation/widgets/board_cell.dart
import 'package:corona_virus/features/game/presentation/helpers/assets_resolver.dart';
import 'package:flutter/material.dart';
import '../../domain/models/virus_model.dart';

class BoardCell extends StatelessWidget {
  final VirusModel cell;
  final bool isCritical; // is virus about to show its reactions
  final VoidCallback onTap;
  final Color? cellColor;

  const BoardCell({
    super.key,
    required this.cell,
    required this.cellColor,
    required this.isCritical,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final asset = AssetsResolver.resolve(
      virusCount: cell.virusCount,
      isCritical: isCritical,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white12, width: 0.5),
        ),
        padding: const EdgeInsets.all(4.0),
        child: asset == null
            ? const SizedBox.expand()
            : ColorFiltered(
                colorFilter: ColorFilter.mode(
                  cellColor ?? Colors.red,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  asset,
                  gaplessPlayback: true,
                  fit: BoxFit.contain,
                ),
              ),
      ),
    );
  }
}
