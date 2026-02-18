import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/number_format.dart';
import '../widgets/purchase_button.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _registeredOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_registeredOpen) {
      return;
    }
    _registeredOpen = true;
    context.read<GameController>().registerShopOpened();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        final income5m = controller.incomePerSecond * 300;

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
          children: [
            const ArcadePanel(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              tint: Color(0xFF172554),
              child: Text(
                'BLACK MARKET  Grab temporary boosts and spikes',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ShopCard(
              title: '2x Income for 15 min',
              subtitle: 'Boost all station profits instantly.',
              children: [
                PurchaseButton(
                  label: 'Buy for 500 coins',
                  enabled: controller.coins >= 500,
                  backgroundColor: const Color(0xFF0EA5E9),
                  onPressed: controller.buyDoubleIncomeBoostWithCoins,
                ),
                const SizedBox(height: 8),
                PurchaseButton(
                  label: 'Watch Rewarded Ad',
                  backgroundColor: const Color(0xFF1D4ED8),
                  onPressed: () async {
                    final success = await controller
                        .watchAdForDoubleIncomeBoost();
                    if (!context.mounted) {
                      return;
                    }
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('2x income activated.')),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ShopCard(
              title: 'Instant Cash Pack',
              subtitle:
                  'Receive 5 minutes of income now (+${formatCoins(income5m)}).',
              children: [
                PurchaseButton(
                  label: 'Buy for 300 coins',
                  enabled: controller.coins >= 300,
                  backgroundColor: const Color(0xFF16A34A),
                  onPressed: controller.buyInstantIncomePack,
                ),
                const SizedBox(height: 8),
                PurchaseButton(
                  label: 'Watch Rewarded Ad',
                  backgroundColor: const Color(0xFF15803D),
                  onPressed: () async {
                    final success = await controller.watchAdForInstantIncome();
                    if (!context.mounted) {
                      return;
                    }
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Instant income granted.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ShopCard(
              title: 'Remove Ads',
              subtitle: 'IAP placeholder (out of scope for this MVP).',
              children: [
                PurchaseButton(
                  label: 'Coming Soon',
                  enabled: false,
                  backgroundColor: const Color(0xFF6B7280),
                  onPressed: null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFFF8FAFC),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
