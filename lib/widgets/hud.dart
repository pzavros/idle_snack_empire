import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import 'animated_coin_counter.dart';
import 'number_format.dart';

class Hud extends StatelessWidget {
  const Hud({
    super.key,
    required this.controller,
    required this.onAvatarTapped,
    required this.onPrestigeTapped,
  });

  final GameController controller;
  final VoidCallback onAvatarTapped;
  final VoidCallback onPrestigeTapped;

  @override
  Widget build(BuildContext context) {
    final avatar = controller.selectedAvatar;
    final theme = controller.selectedTheme;
    final rank = _rankFromLifetime(controller.lifetimeCoins);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTapped,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatar.color.withValues(alpha: 0.18),
                border: Border.all(color: avatar.color.withValues(alpha: 0.4)),
              ),
              child: Icon(avatar.icon, color: avatar.color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCoinCounter(
                  coins: controller.coins,
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    color: Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Income/sec: ${formatCoins(controller.incomePerSecond)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Rank: $rank',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (controller.collectCombo >= 2)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFFF59E0B).withValues(alpha: 0.17),
              ),
              child: Text(
                'Combo x${controller.collectCombo}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309),
                  fontSize: 11,
                ),
              ),
            ),
          if (controller.hasActiveDoubleBoost)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: theme.stationAccent.withValues(alpha: 0.16),
              ),
              child: Text(
                '2x ${formatDuration(controller.activeDoubleBoostRemaining)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.stationAccent,
                  fontSize: 11,
                ),
              ),
            ),
          if (controller.canPrestige)
            IconButton(
              tooltip: 'Prestige',
              onPressed: onPrestigeTapped,
              icon: const Icon(Icons.workspace_premium),
            ),
        ],
      ),
    );
  }

  String _rankFromLifetime(double lifetimeCoins) {
    if (lifetimeCoins >= 5000000) {
      return 'Galactic Snack Mogul';
    }
    if (lifetimeCoins >= 1000000) {
      return 'Snack Overlord';
    }
    if (lifetimeCoins >= 200000) {
      return 'Franchise Master';
    }
    if (lifetimeCoins >= 50000) {
      return 'Kitchen Tycoon';
    }
    if (lifetimeCoins >= 10000) {
      return 'Rising Cook';
    }
    return 'Street Vendor';
  }
}
