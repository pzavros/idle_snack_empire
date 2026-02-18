import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';

class GameMomentOverlay extends StatelessWidget {
  const GameMomentOverlay({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<List<GameMomentEvent>>(
        valueListenable: controller.gameMomentEvents,
        builder: (context, events, child) {
          return Stack(
            children: [
              for (var i = 0; i < events.length; i++)
                _GameMomentToast(
                  key: ValueKey<int>(events[i].id),
                  event: events[i],
                  topOffset: 96 + (i * 54),
                  onDone: () => controller.removeGameMoment(events[i].id),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GameMomentToast extends StatefulWidget {
  const _GameMomentToast({
    super.key,
    required this.event,
    required this.topOffset,
    required this.onDone,
  });

  final GameMomentEvent event;
  final double topOffset;
  final VoidCallback onDone;

  @override
  State<_GameMomentToast> createState() => _GameMomentToastState();
}

class _GameMomentToastState extends State<_GameMomentToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..forward();

    _slide = Tween<double>(begin: -22, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4)),
    );
    Future<void>.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) {
        return;
      }
      _controller.reverseDuration = const Duration(milliseconds: 360);
      _controller.reverse().then((_) {
        widget.onDone();
      });
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
        final progress = _controller.value;
        return Positioned(
          left: 16,
          right: 16,
          top: widget.topOffset + _slide.value,
          child: Opacity(
            opacity: progress.clamp(0, 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.event.color.withValues(alpha: 0.8),
                  width: 1.3,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.event.color,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          widget.event.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
