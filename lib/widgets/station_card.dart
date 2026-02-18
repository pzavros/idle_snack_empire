import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../models/station.dart';
import 'number_format.dart';
import 'purchase_button.dart';

class StationCard extends StatelessWidget {
  const StationCard({
    super.key,
    required this.station,
    required this.controller,
  });

  final Station station;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([station, controller]),
      builder: (context, child) {
        final accent = controller.selectedTheme.stationAccent;

        if (!station.isUnlocked) {
          final canUnlock = controller.canUnlockStation(station);
          final hasCoinRequirement =
              controller.coins >= station.definition.unlockCost;
          final hasLevelRequirement = controller.meetsUnlockLevelRequirement(
            station,
          );
          final requirementLabel = controller.unlockRequirementDescription(
            station,
          );

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    station.definition.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.definition.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unlock for ${formatCoins(station.definition.unlockCost)}',
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Coins: ${hasCoinRequirement ? 'Ready' : 'Missing'}',
                        style: TextStyle(
                          color: hasCoinRequirement
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFCA5A5),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        requirementLabel,
                        style: TextStyle(
                          color: hasLevelRequirement
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFCA5A5),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 94,
                  child: PurchaseButton(
                    label: 'Unlock',
                    enabled: canUnlock,
                    backgroundColor: accent,
                    onPressed: () => controller.unlockStation(station),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final levelCost = controller.levelUpCostForStation(station);
        final canLevel = controller.coins >= levelCost;
        final queued = station.pendingCollections;
        final canCollect = queued > 0;
        final isCharged = canCollect && !station.isAutomated;
        final cycleSeconds = station.effectiveCycleSeconds(
          controller.currentGlobalSpeedMultiplier,
        );

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF111827), Color(0xFF1F2937)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCharged
                  ? accent.withValues(alpha: 0.7)
                  : accent.withValues(alpha: 0.12),
              width: isCharged ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              if (isCharged)
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 22,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0.9,
                        end: 0.9 + (station.progress * 0.15),
                      ),
                      duration: const Duration(milliseconds: 180),
                      builder: (context, value, _) {
                        return Transform.scale(
                          scale: value,
                          child: Text(
                            station.definition.icon,
                            style: const TextStyle(fontSize: 25),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.definition.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFFF8FAFC),
                          ),
                        ),
                        Text(
                          'Level ${station.level}',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (station.isAutomated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'AUTO',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${formatCoins(controller.stationProfitPerCycle(station))}/cycle',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${cycleSeconds.toStringAsFixed(1)}s cycle',
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: station.progress),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                builder: (context, value, _) {
                  final clamped = value.clamp(0.0, 1.0).toDouble();
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 10,
                              value: clamped,
                              backgroundColor: const Color(0xFF334155),
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                          if (clamped > 0.02)
                            Positioned(
                              left: (constraints.maxWidth - 10) * clamped,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              if (controller.collectCombo >= 2 && !station.isAutomated)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Combo bonus ${(controller.comboBonusMultiplier * 100 - 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: const Color(0xFFB45309).withValues(alpha: 0.95),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PurchaseButton(
                      label: 'Lvl Up ${formatCoins(levelCost)}',
                      enabled: canLevel,
                      backgroundColor: const Color(0xFF0EA5E9),
                      onPressed: () => controller.buyStationLevel(station),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PulseWrap(
                      active: isCharged,
                      child: _CollectButton(
                        station: station,
                        controller: controller,
                        enabled: canCollect && !station.isAutomated,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: PurchaseButton(
                      label: station.hasProfitUpgrade
                          ? '2x Bought'
                          : '2x Profit ${formatCoins(station.definition.profitUpgradeCost)}',
                      enabled:
                          !station.hasProfitUpgrade &&
                          controller.coins >=
                              station.definition.profitUpgradeCost,
                      backgroundColor: const Color(0xFF7C3AED),
                      onPressed: station.hasProfitUpgrade
                          ? null
                          : () => controller.buyStationProfitUpgrade(station),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PurchaseButton(
                      label: station.isAutomated
                          ? 'Manager Active'
                          : 'Manager ${formatCoins(station.definition.managerCost)}',
                      enabled:
                          !station.isAutomated &&
                          controller.coins >= station.definition.managerCost,
                      backgroundColor: const Color(0xFF16A34A),
                      onPressed: station.isAutomated
                          ? null
                          : () => controller.buyStationManager(station),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              if (!station.isAutomated && queued > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Ready collections: $queued',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CollectButton extends StatelessWidget {
  const _CollectButton({
    required this.station,
    required this.controller,
    required this.enabled,
  });

  final Station station;
  final GameController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PurchaseButton(
      label: station.isAutomated
          ? 'Auto Running'
          : enabled
          ? 'Collect'
          : 'Wait',
      enabled: enabled,
      backgroundColor: const Color(0xFFF59E0B),
      onPressed: () {
        final box = context.findRenderObject();
        Offset? origin;
        if (box is RenderBox) {
          origin = box.localToGlobal(box.size.center(Offset.zero));
        }
        controller.collectStation(station, particleOrigin: origin);
      },
    );
  }
}

class _PulseWrap extends StatefulWidget {
  const _PulseWrap({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_PulseWrap> createState() => _PulseWrapState();
}

class _PulseWrapState extends State<_PulseWrap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _PulseWrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) {
      return;
    }
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return widget.child;
    }
    return ScaleTransition(scale: _controller, child: widget.child);
  }
}
