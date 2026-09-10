import 'package:corona_virus/themes/player_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../animations/reaction_animation.dart';
import '../animations/reaction_animation_controller.dart';
import '../animations/reaction_timeline.dart';

class ReactionAnimationOverlay extends StatelessWidget {
  final ReactionAnimationController controller;

  /// Size of the entire game board.
  final Size boardSize;

  /// Number of rows and columns in the board.
  final int rows;
  final int columns;

  const ReactionAnimationOverlay({
    super.key,
    required this.controller,
    required this.boardSize,
    required this.rows,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final wave = controller.currentWave;

          if (wave == null) {
            return const SizedBox.shrink();
          }
          if (wave != null) {
            debugPrint(
              '[ReactionWave] '
              'depth=${wave.depth} | '
              'animations=${wave.animations.length} | '
              'spreads=${wave.spreadCount} | '
              'explosions=${wave.explosionCount}',
            );
          }
          return IgnorePointer(
            child: Stack(
              children: [
                for (final animation in wave.animations)
                  if (animation.isSpread)
                    _MovingVirus(
                      animation: animation,
                      controller: controller,
                      boardSize: boardSize,
                      rows: rows,
                      columns: columns,
                    ),
              ],
            ),
          );
        });
  }
}

class _MovingVirus extends StatefulWidget {
  final ReactionAnimation animation;
  final Size boardSize;
  final int rows;
  final int columns;
  final ReactionAnimationController controller;

  const _MovingVirus({
    required this.animation,
    required this.controller,
    required this.boardSize,
    required this.rows,
    required this.columns,
  });

  @override
  State<_MovingVirus> createState() => _MovingVirusState();
}

class _MovingVirusState extends State<_MovingVirus> {
  final Set<int> _loggedPoints = {};

  @override
  Widget build(BuildContext context) {
    final animation = widget.animation;
    final controller = widget.controller;

    final cellWidth = widget.boardSize.width / widget.columns;
    final cellHeight = widget.boardSize.height / widget.rows;

    final startX = animation.col * cellWidth;
    final startY = animation.row * cellHeight;

    final endX = animation.toCol! * cellWidth;
    final endY = animation.toRow! * cellHeight;

    final rawProgress = controller.depthProgress;

    final progress = Curves.easeOutCubic.transform(
      rawProgress.clamp(0.0, 1.0),
    );

    final x = startX + ((endX - startX) * progress);
    final y = startY + ((endY - startY) * progress);

    _logPosition(
      animation: animation,
      rawProgress: rawProgress,
      progress: progress,
      x: x,
      y: y,
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
    );

    if (!controller.isPlaying || rawProgress >= 1.0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: x,
      top: y,
      width: cellWidth,
      height: cellHeight,
      child: Center(
        child: _buildVirus(),
      ),
    );
  }

  void _logPosition({
    required ReactionAnimation animation,
    required double rawProgress,
    required double progress,
    required double x,
    required double y,
    required double startX,
    required double startY,
    required double endX,
    required double endY,
  }) {
    int point;

    if (rawProgress < 0.05) {
      point = 0;
    } else if (rawProgress < 0.50) {
      point = 50;
    } else if (rawProgress < 0.95) {
      point = 75;
    } else {
      point = 100;
    }

    if (_loggedPoints.contains(point)) return;

    _loggedPoints.add(point);

    debugPrint(
      '[VisualMove] '
      'depth=${animation.chainDepth} | '
      'FROM=(${animation.row},${animation.col}) '
      'TO=(${animation.toRow},${animation.toCol}) | '
      'point=$point% | '
      'raw=${rawProgress.toStringAsFixed(2)} | '
      'eased=${progress.toStringAsFixed(2)} | '
      'position=(${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}) | '
      'start=(${startX.toStringAsFixed(1)},${startY.toStringAsFixed(1)}) | '
      'end=(${endX.toStringAsFixed(1)},${endY.toStringAsFixed(1)})',
    );
  }

  Widget _buildVirus() {
    final color = PlayerColors.fromIndex(widget.animation.playerId);

    return SvgPicture.asset(
      'assets/images/virus.svg',
      colorFilter: ColorFilter.mode(
        color,
        BlendMode.srcIn,
      ),
    );
  }
}
