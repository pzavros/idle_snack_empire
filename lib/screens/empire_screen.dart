import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/number_format.dart';
import '../widgets/purchase_button.dart';
import '../widgets/station_card.dart';

class EmpireScreen extends StatelessWidget {
  const EmpireScreen({super.key, required this.onPrestigePressed});

  final VoidCallback onPrestigePressed;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            ArcadePanel(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              padding: const EdgeInsets.all(14),
              tint: const Color(0xFF0B1221),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KITCHEN FLOOR',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: Colors.white.withValues(alpha: 0.96),
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lifetime: ${formatCoins(controller.lifetimeCoins)}',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Golden Chips: ${controller.goldenChips} '
                          '(${controller.permanentIncomeMultiplier.toStringAsFixed(2)}x)',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Prestige Run: ${formatCoins(controller.runCoinsSincePrestige)} / '
                          '${formatCoins(controller.nextPrestigeThreshold)}',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${controller.currentStageLabel}  ${controller.currentStageName}',
                          style: const TextStyle(
                            color: Color(0xFFBFDBFE),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        if (controller.nextStageUnlockCost != null)
                          Text(
                            'Next stage starts at '
                            '${formatCoins(controller.nextStageUnlockCost!)}',
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: controller.currentStageProgress,
                            backgroundColor: const Color(0xFF334155),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (controller.canPrestige)
                    SizedBox(
                      width: 120,
                      child: PurchaseButton(
                        label: 'Prestige',
                        backgroundColor: const Color(0xFFD97706),
                        onPressed: onPrestigePressed,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 88),
                itemCount: controller.stations.length,
                itemBuilder: (context, index) {
                  final station = controller.stations[index];
                  return StationCard(station: station, controller: controller);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
