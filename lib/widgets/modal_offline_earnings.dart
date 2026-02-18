import 'package:flutter/material.dart';

import 'number_format.dart';
import 'purchase_button.dart';

class OfflineEarningsModal extends StatelessWidget {
  const OfflineEarningsModal({
    super.key,
    required this.awayDuration,
    required this.baseCoins,
    required this.onCollect,
    required this.onCollectDouble,
  });

  final Duration awayDuration;
  final double baseCoins;
  final VoidCallback onCollect;
  final VoidCallback onCollectDouble;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Offline Earnings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'You were away for ${formatDuration(awayDuration)}',
              style: const TextStyle(color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '+${formatCoins(baseCoins)} coins',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            PurchaseButton(
              label: 'Collect',
              onPressed: onCollect,
              backgroundColor: const Color(0xFF16A34A),
            ),
            const SizedBox(height: 8),
            PurchaseButton(
              label: 'Watch Ad to 2x',
              onPressed: onCollectDouble,
              backgroundColor: const Color(0xFF2563EB),
            ),
          ],
        ),
      ),
    );
  }
}
