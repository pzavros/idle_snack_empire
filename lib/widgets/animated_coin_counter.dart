import 'package:flutter/material.dart';

import 'number_format.dart';

class AnimatedCoinCounter extends StatelessWidget {
  const AnimatedCoinCounter({super.key, required this.coins, this.textStyle});

  final double coins;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final display = formatCoins(coins);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: Text(
        key: ValueKey<String>(display),
        '🪙 $display',
        style: textStyle ?? Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
