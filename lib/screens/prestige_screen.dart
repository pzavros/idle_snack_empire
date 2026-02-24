import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../widgets/number_format.dart';
import '../widgets/purchase_button.dart';

class PrestigeScreen extends StatelessWidget {
  const PrestigeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prestige')),
      body: Consumer<GameController>(
        builder: (context, controller, child) {
          final gain = controller.estimatedPrestigeGain;
          final gainLabel = gain == 1 ? 'Level' : 'Levels';
          final canPrestige = controller.canPrestige;
          final threshold = controller.nextPrestigeThreshold;
          final remaining = (threshold - controller.runCoinsSincePrestige)
              .clamp(0.0, double.infinity)
              .toDouble();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Empire Level',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current Level: ${controller.empireLevel}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Permanent Multiplier: '
                      '${controller.permanentIncomeMultiplier.toStringAsFixed(2)}x',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Each Empire Level adds +0.5x permanent income.',
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prestiges: ${controller.prestigeCount}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Run coins (since last prestige): '
                      '${formatCoins(controller.runCoinsSincePrestige)}',
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    ),
                    Text(
                      'Next prestige threshold: ${formatCoins(threshold)}',
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: controller.prestigeProgress,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      canPrestige
                          ? 'Ready to prestige now.'
                          : '${formatCoins(remaining)} more run coins needed.',
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Difficulty scaling: each prestige doubles the next threshold '
                      '(1M, 2M, 4M, 8M...).',
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'If you reset now you gain +$gain Empire $gainLabel.\n'
                      'Reset clears coins, stations, upgrades, and temporary boosts,\n'
                      'but keeps Empire Level, cosmetics, and total lifetime stats.',
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    ),
                    const SizedBox(height: 16),
                    PurchaseButton(
                      label: canPrestige
                          ? 'Prestige +$gain $gainLabel'
                          : 'Need ${formatCoins(remaining)} more',
                      enabled: canPrestige,
                      backgroundColor: const Color(0xFFD97706),
                      onPressed: canPrestige
                          ? () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Prestige'),
                                    content: Text(
                                      'Reset all stations and coins for $gain Empire $gainLabel?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Prestige'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmed != true || !context.mounted) {
                                return;
                              }

                              final result = controller.performPrestigeReset();
                              if (!context.mounted) {
                                return;
                              }

                              if (result) {
                                Navigator.of(context).pop();
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
