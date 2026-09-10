import 'dart:math';
import 'package:corona_virus/themes/player_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/models/virus_model.dart';

class VirusView extends StatelessWidget {
  final bool visible;
  final VirusModel virus;
  final Color? virusColor;
  final bool isCritical;
  const VirusView({
    super.key,
    required this.virus,
    this.virusColor,
    required this.isCritical,
    this.visible = true,
  });

  Widget _virus() {
    final color = PlayerColors.fromIndex(virus.playerId ?? 1);
    if (virus.virusCount > 1) {
      return OrbitingVirus(
          virusCount: virus.virusCount, spinFast: isCritical, color: color);
    } else if (virus.virusCount < 1) {
      return SizedBox.shrink();
    } else {
      return SpinningVirus(spinFast: isCritical, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: _virus(),
    );
  }
}

class SpinningVirus extends StatefulWidget {
  final bool spinFast;
  final Color color;
  const SpinningVirus({super.key, required this.spinFast, required this.color});

  @override
  State<SpinningVirus> createState() => _SpinningVirusState();
}

class _SpinningVirusState extends State<SpinningVirus>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Duration get spinDuration {
    return widget.spinFast
        ? const Duration(seconds: 2)
        : const Duration(seconds: 4);
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: spinDuration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant SpinningVirus oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.spinFast != widget.spinFast) {
      _controller
        ..duration = spinDuration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SvgPicture.asset(
          'assets/images/virus.svg',
          colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
        ),
      ),
      builder: (_, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * pi,
          child: child,
        );
      },
    );
  }
}

class OrbitingVirus extends StatefulWidget {
  static const String assetPath = 'assets/images/virus.svg';
  static const double orbitRadiusRatio = 0.6;
  final int virusCount;
  final Color color;
  final bool spinFast;

  const OrbitingVirus({
    super.key,
    required this.color,
    this.virusCount = 2,
    this.spinFast = false,
  }) : assert(virusCount == 2 || virusCount == 3);

  @override
  State<OrbitingVirus> createState() => _OrbitingVirusState();
}

class _OrbitingVirusState extends State<OrbitingVirus>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Duration get orbitDuration {
    return widget.spinFast
        ? const Duration(seconds: 1)
        : const Duration(seconds: 4);
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: orbitDuration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant OrbitingVirus oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.spinFast != widget.spinFast ||
        oldWidget.virusCount != widget.virusCount) {
      _controller
        ..duration = orbitDuration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableSize = min(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final virusSize = availableSize / 2.5;
        final orbitRadius = virusSize * OrbitingVirus.orbitRadiusRatio;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final rotation = _controller.value * 2 * pi;

            return Stack(
              alignment: Alignment.center,
              children: [
                for (int i = 0; i < widget.virusCount; i++)
                  Transform.rotate(
                    angle: rotation,
                    child: Transform.translate(
                      offset: Offset(
                        cos(i * 2 * pi / widget.virusCount) * orbitRadius,
                        sin(i * 2 * pi / widget.virusCount) * orbitRadius,
                      ),
                      child: Transform.rotate(
                        angle: -rotation,
                        child: SvgPicture.asset(
                          OrbitingVirus.assetPath,
                          colorFilter:
                              ColorFilter.mode(widget.color, BlendMode.srcIn),
                          width: virusSize,
                          height: virusSize,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

///
/// Spinning Virus => Single static virus no much logic on it
///  spinFast = true if its about to split
///   spinFast = false if its not volatile yet
///
