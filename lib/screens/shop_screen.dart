import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/number_format.dart';
import '../widgets/purchase_button.dart';

enum _ShopLane { boostAds, cashAds, specialAds }

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _registeredOpen = false;
  _ShopLane _lane = _ShopLane.boostAds;
  int _dealCountdown = 120;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _dealCountdown = _dealCountdown <= 1 ? 120 : _dealCountdown - 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
        final incomePerSecond = controller.incomePerSecond;
        final income5m = incomePerSecond * 300;
        final income10m = incomePerSecond * 600;

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
          children: [
            const ArcadePanel(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              tint: Color(0xFF172554),
              child: Text(
                'AD VAULT  All rewards are ad-powered',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _ShopTelemetry(
              incomePerSecond: incomePerSecond,
              hasBoost: controller.hasActiveDoubleBoost,
              boostRemaining: controller.activeDoubleBoostRemaining,
              dealCountdown: _dealCountdown,
            ),
            const SizedBox(height: 12),
            _LaneSelector(
              selected: _lane,
              onSelect: (lane) => setState(() => _lane = lane),
            ),
            const SizedBox(height: 12),
            if (_lane == _ShopLane.boostAds) ...[
              _AdOfferCard(
                title: '2x Income Protocol',
                channel: 'BOOST_REWARDED',
                subtitle: 'Watch ad for 15 minutes of 2x income.',
                detail: 'Best before a long idle session.',
                badge: 'Core Boost',
                badgeColor: const Color(0xFF0EA5E9),
                buttonLabel: 'Watch Ad: Activate 2x',
                buttonColor: const Color(0xFF0EA5E9),
                onPressed: () async {
                  final success = await controller
                      .watchAdForDoubleIncomeBoost();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? '2x income activated for 15 minutes.'
                            : 'Reward unavailable. Try again.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _AdOfferCard(
                title: 'Promo Bundle',
                channel: 'BUNDLE_REWARDED',
                subtitle:
                    'Watch ad for mini bundle: 2x income for 5m + instant 4m cash.',
                detail: 'Fast hybrid boost for breaking upgrade walls.',
                badge: 'Hybrid',
                badgeColor: const Color(0xFF7C3AED),
                buttonLabel: 'Watch Ad: Claim Bundle',
                buttonColor: const Color(0xFF7C3AED),
                onPressed: () async {
                  final success = await controller.watchAdForTycoonBundle();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Promo bundle claimed.'
                            : 'Reward unavailable. Try again.',
                      ),
                    ),
                  );
                },
              ),
            ],
            if (_lane == _ShopLane.cashAds) ...[
              _AdOfferCard(
                title: 'Instant Cash Pack',
                channel: 'CASH_REWARDED',
                subtitle:
                    'Watch ad for instant 5-minute cash (+${formatCoins(income5m)}).',
                detail: 'Quick refill for manager and upgrade purchases.',
                badge: 'Instant',
                badgeColor: const Color(0xFF16A34A),
                buttonLabel: 'Watch Ad: Claim 5m Cash',
                buttonColor: const Color(0xFF16A34A),
                onPressed: () async {
                  final success = await controller.watchAdForInstantIncome();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Instant 5-minute cash granted.'
                            : 'Reward unavailable. Try again.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _AdOfferCard(
                title: 'Mega Cash Drop',
                channel: 'CASH_REWARDED_PLUS',
                subtitle:
                    'Watch ad for instant 10-minute cash (+${formatCoins(income10m)}).',
                detail: 'Heavy economy spike when you need a big push.',
                badge: 'Heavy Cash',
                badgeColor: const Color(0xFF22C55E),
                buttonLabel: 'Watch Ad: Claim 10m Cash',
                buttonColor: const Color(0xFF22C55E),
                onPressed: () async {
                  final success = await controller.watchAdForMegaCashDrop();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Mega cash drop granted.'
                            : 'Reward unavailable. Try again.',
                      ),
                    ),
                  );
                },
              ),
            ],
            if (_lane == _ShopLane.specialAds) ...[
              _AdOfferCard(
                title: 'Jackpot Crate',
                channel: 'JACKPOT_REWARDED',
                subtitle:
                    'Watch ad for random high-value reward (boost, cash, or hybrid).',
                detail: 'Risk-free roll with variable payouts.',
                badge: 'Random',
                badgeColor: const Color(0xFFF59E0B),
                buttonLabel: 'Watch Ad: Open Crate',
                buttonColor: const Color(0xFFD97706),
                onPressed: () async {
                  final result = await controller.watchAdForJackpotCrate();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result != null
                            ? 'Jackpot: $result'
                            : 'Reward unavailable. Try again.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _AdOfferCard(
                title: 'Tycoon Burst',
                channel: 'BUNDLE_REWARDED_ALT',
                subtitle:
                    'Watch ad for balanced economy spike (boost + instant cash).',
                detail: 'Safe option when you do not want random outcomes.',
                badge: 'Reliable',
                badgeColor: const Color(0xFF6366F1),
                buttonLabel: 'Watch Ad: Burst',
                buttonColor: const Color(0xFF6366F1),
                onPressed: () async {
                  final success = await controller.watchAdForTycoonBundle();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Tycoon burst applied.'
                            : 'Reward unavailable. Try again.',
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            _AdOfferCard(
              title: 'Remove Ads',
              channel: 'IAP_PLACEHOLDER',
              subtitle: 'IAP placeholder (out of scope for this MVP).',
              detail: 'Not active in this build.',
              badge: 'Placeholder',
              badgeColor: const Color(0xFF6B7280),
              buttonLabel: 'Coming Soon',
              buttonColor: const Color(0xFF6B7280),
              enabled: false,
              onPressed: null,
            ),
          ],
        );
      },
    );
  }
}

class _ShopTelemetry extends StatelessWidget {
  const _ShopTelemetry({
    required this.incomePerSecond,
    required this.hasBoost,
    required this.boostRemaining,
    required this.dealCountdown,
  });

  final double incomePerSecond;
  final bool hasBoost;
  final Duration boostRemaining;
  final int dealCountdown;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Income/sec',
            value: formatCoins(incomePerSecond),
            color: const Color(0xFF22D3EE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            label: '2x Status',
            value: hasBoost ? _formatDuration(boostRemaining) : 'Inactive',
            color: hasBoost ? const Color(0xFF4ADE80) : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            label: 'Flash Cycle',
            value: '${dealCountdown}s',
            color: const Color(0xFFF97316),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (minutes <= 0) {
      return '${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LaneSelector extends StatelessWidget {
  const _LaneSelector({required this.selected, required this.onSelect});

  final _ShopLane selected;
  final ValueChanged<_ShopLane> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LaneChip(
            label: 'Boost Ads',
            selected: selected == _ShopLane.boostAds,
            onTap: () => onSelect(_ShopLane.boostAds),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LaneChip(
            label: 'Cash Ads',
            selected: selected == _ShopLane.cashAds,
            onTap: () => onSelect(_ShopLane.cashAds),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LaneChip(
            label: 'Special Ads',
            selected: selected == _ShopLane.specialAds,
            onTap: () => onSelect(_ShopLane.specialAds),
          ),
        ),
      ],
    );
  }
}

class _LaneChip extends StatelessWidget {
  const _LaneChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? const Color(0xFF0EA5E9).withValues(alpha: 0.22)
              : const Color(0xFF334155).withValues(alpha: 0.45),
          border: Border.all(
            color: selected
                ? const Color(0xFF38BDF8)
                : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? const Color(0xFFBAE6FD) : const Color(0xFFCBD5E1),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _AdOfferCard extends StatelessWidget {
  const _AdOfferCard({
    required this.title,
    required this.channel,
    required this.subtitle,
    required this.detail,
    required this.badge,
    required this.badgeColor,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onPressed,
    this.enabled = true,
  });

  final String title;
  final String channel;
  final String subtitle;
  final String detail;
  final String badge;
  final Color badgeColor;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback? onPressed;
  final bool enabled;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFFF8FAFC),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: badgeColor.withValues(alpha: 0.2),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ad Channel: $channel',
            style: const TextStyle(
              color: Color(0xFFBFDBFE),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          PurchaseButton(
            label: buttonLabel,
            enabled: enabled,
            backgroundColor: buttonColor,
            onPressed: enabled ? onPressed : null,
          ),
        ],
      ),
    );
  }
}
