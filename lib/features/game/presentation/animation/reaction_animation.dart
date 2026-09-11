import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/events/game_events.dart';

class ReactionAnimationLayer extends StatefulWidget {
  const ReactionAnimationLayer({
    super.key,
    required this.events,
    required this.rows,
    required this.cols,
    required this.playerColor,
    required this.onDepthFinished,
    required this.onFinished,
    required this.onHiddenCellsChanged,
  });

  final List<GameEvent> events;
  final int rows;
  final int cols;
  final ValueChanged<Set<String>> onHiddenCellsChanged;
  final Color Function(int playerId) playerColor;

  /// Called after each reaction depth finishes.
  final Future<void> Function(
    int depth,
    List<CellUpdated> updates,
  ) onDepthFinished;

  /// Called when the complete reaction finishes.
  final VoidCallback onFinished;

  @override
  State<ReactionAnimationLayer> createState() => _ReactionAnimationLayerState();
}

class _ReactionAnimationLayerState extends State<ReactionAnimationLayer>
    with TickerProviderStateMixin {
  final List<_MovingVirus> _movingViruses = [];

  /// Cells whose normal virus should temporarily disappear.
  final Set<String> _hiddenCells = {};

  bool _playing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startReaction();
    });
  }

  @override
  void didUpdateWidget(
    covariant ReactionAnimationLayer oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.events != widget.events) {
      _clearMovingViruses();
      _hiddenCells.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startReaction();
      });
    }
  }

  @override
  void dispose() {
    _clearMovingViruses();
    super.dispose();
  }

  Future<void> _startReaction() async {
    if (_playing || !mounted) return;

    _playing = true;

    final explosions = widget.events.whereType<VirusExploded>().toList();

    if (explosions.isEmpty) {
      _finish();
      return;
    }

    final maxDepth = explosions.fold<int>(
      0,
      (max, event) => math.max(
        max,
        event.chainDepth,
      ),
    );

    for (int depth = 1; depth <= maxDepth; depth++) {
      if (!mounted) return;

      await _playDepth(depth);
    }

    _finish();
  }

  Future<void> _playDepth(int depth) async {
    if (!mounted) return;

    final explosions = widget.events
        .whereType<VirusExploded>()
        .where(
          (event) => event.chainDepth == depth,
        )
        .toList();

    final spreads = widget.events
        .whereType<VirusSpread>()
        .where(
          (event) => event.chainDepth == depth,
        )
        .toList();

    final updates = widget.events
        .whereType<CellUpdated>()
        .where(
          (event) => _belongsToDepth(
            event,
            depth,
          ),
        )
        .toList();

    /*
     * ----------------------------------------------------------
     * STEP 1
     * Hide the source cells that are about to explode.
     * ----------------------------------------------------------
     */

    for (final spread in spreads) {
      _hiddenCells.add(
        _cellKey(
          spread.fromRow,
          spread.fromCol,
        ),
      );
    }
    widget.onHiddenCellsChanged(_hiddenCells);
    if (mounted) {
      setState(() {});
    }

    /*
     * ----------------------------------------------------------
     * STEP 2
     * Small pause so the source visibly disappears before
     * the viruses start moving.
     * ----------------------------------------------------------
     */

    if (explosions.isNotEmpty) {
      await Future<void>.delayed(
        const Duration(milliseconds: 80),
      );
    }

    if (!mounted) return;

    /*
     * ----------------------------------------------------------
     * STEP 3
     * Create moving viruses.
     * ----------------------------------------------------------
     */

    _clearMovingViruses();
    widget.onHiddenCellsChanged({});
    for (final spread in spreads) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(
          milliseconds: 220,
        ),
      );

      _movingViruses.add(
        _MovingVirus(
          event: spread,
          controller: controller,
          color: widget.playerColor(
            spread.playerId,
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }

    /*
     * ----------------------------------------------------------
     * STEP 4
     * Start all viruses for this depth together.
     * ----------------------------------------------------------
     */

    final animations = <Future<void>>[];

    for (final virus in _movingViruses) {
      animations.add(
        virus.controller.forward(),
      );
    }

    if (animations.isNotEmpty) {
      await Future.wait(animations);
    }

    if (!mounted) return;

    /*
     * ----------------------------------------------------------
     * STEP 5
     * Viruses have arrived.
     *
     * Remove the moving overlay.
     * ----------------------------------------------------------
     */

    _clearMovingViruses();

    /*
     * Source cells remain hidden until the board state is
     * updated by the controller.
     */

    if (mounted) {
      setState(() {});
    }

    /*
     * ----------------------------------------------------------
     * STEP 6
     * Tell GameController to commit this depth's board changes.
     * ----------------------------------------------------------
     */

    await widget.onDepthFinished(
      depth,
      updates,
    );

    if (!mounted) return;

    /*
     * ----------------------------------------------------------
     * STEP 7
     * Allow the board to render the new state.
     * ----------------------------------------------------------
     */

    _hiddenCells.clear();

    if (mounted) {
      setState(() {});
    }

    /*
     * Tiny pause before the next chain depth.
     */

    await Future<void>.delayed(
      const Duration(milliseconds: 50),
    );
  }

  bool _belongsToDepth(CellUpdated event, int depth) {
    return event.chainDepth == depth;
  }

  String _cellKey(
    int row,
    int col,
  ) {
    return '$row:$col';
  }

  bool isCellHidden(
    int row,
    int col,
  ) {
    return _hiddenCells.contains(
      _cellKey(row, col),
    );
  }

  void _finish() {
    if (!mounted) return;

    _clearMovingViruses();
    _hiddenCells.clear();

    setState(() {});

    _playing = false;

    widget.onFinished();
  }

  void _clearMovingViruses() {
    for (final virus in _movingViruses) {
      virus.controller.dispose();
    }

    _movingViruses.clear();
  }

  Offset _cellCenter({
    required int row,
    required int col,
    required double cellWidth,
    required double cellHeight,
  }) {
    return Offset(
      col * cellWidth + cellWidth / 2,
      row * cellHeight + cellHeight / 2,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final cellWidth = constraints.maxWidth / widget.cols;

          final cellHeight = constraints.maxHeight / widget.rows;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final virus in _movingViruses)
                _buildMovingVirus(
                  virus,
                  cellWidth,
                  cellHeight,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMovingVirus(
    _MovingVirus virus,
    double cellWidth,
    double cellHeight,
  ) {
    final event = virus.event;

    final from = _cellCenter(
      row: event.fromRow,
      col: event.fromCol,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );

    final to = _cellCenter(
      row: event.toRow,
      col: event.toCol,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );

    final size = math.min(
          cellWidth,
          cellHeight,
        ) *
        0.35;

    return AnimatedBuilder(
      animation: virus.controller,
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          'assets/images/virus.svg',
          colorFilter: ColorFilter.mode(
            virus.color,
            BlendMode.srcIn,
          ),
        ),
      ),
      builder: (
        context,
        child,
      ) {
        final rawT = virus.controller.value;

        final t = Curves.easeInOut.transform(rawT);

        final position = Offset.lerp(
          from,
          to,
          t,
        )!;

        final scale = 0.75 +
            (math.sin(
                  rawT * math.pi,
                ) *
                0.25);

        return Positioned(
          left: position.dx - size / 2,
          top: position.dy - size / 2,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
    );
  }
}

class _MovingVirus {
  final VirusSpread event;
  final AnimationController controller;
  final Color color;

  const _MovingVirus({
    required this.event,
    required this.controller,
    required this.color,
  });
}
