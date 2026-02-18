import 'dart:math';

import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import 'number_format.dart';

class CoinParticleOverlay extends StatelessWidget {
  const CoinParticleOverlay({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<List<CoinParticleEvent>>(
        valueListenable: controller.coinParticleEvents,
        builder: (context, events, child) {
          return Stack(
            children: [
              for (final event in events)
                _CoinParticle(
                  key: ValueKey<int>(event.id),
                  event: event,
                  onDone: () => controller.removeCoinParticle(event.id),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CoinParticle extends StatefulWidget {
  const _CoinParticle({super.key, required this.event, required this.onDone});

  final CoinParticleEvent event;
  final VoidCallback onDone;

  @override
  State<_CoinParticle> createState() => _CoinParticleState();
}

class _CoinParticleState extends State<_CoinParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _yOffset;
  late final Animation<double> _xOffset;
  late final Animation<double> _scale;
  late final int _coinSpriteCount;

  @override
  void initState() {
    super.initState();
    final random = Random(widget.event.id * 91);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _yOffset = Tween<double>(
      begin: 0,
      end: -56 - random.nextDouble() * 30,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _xOffset = Tween<double>(
      begin: 0,
      end: (random.nextDouble() - 0.5) * 70,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _coinSpriteCount = 1 + random.nextInt(3);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDone();
      }
    });
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
      builder: (context, child) {
        return Positioned(
          left: widget.event.origin.dx - 30 + _xOffset.value,
          top: widget.event.origin.dy + _yOffset.value,
          child: Opacity(
            opacity: 1 - _controller.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade200, Colors.amber.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.shade700.withValues(alpha: 0.5),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      List<String>.filled(_coinSpriteCount, '🪙').join(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${formatCoins(widget.event.amount)}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
