import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/economy.dart';
import '../controllers/game_controller.dart';
import '../models/station.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/number_format.dart';
import '../widgets/purchase_button.dart';

enum _UpgradeFilter { all, affordable, pending }

class UpgradesScreen extends StatefulWidget {
  const UpgradesScreen({super.key});

  @override
  State<UpgradesScreen> createState() => _UpgradesScreenState();
}

class _UpgradesScreenState extends State<UpgradesScreen> {
  _UpgradeFilter _filter = _UpgradeFilter.all;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        final currentIncome = controller.incomePerSecond;
        final profitTier = controller.state.globalUpgrades.profitTier;
        final speedTier = controller.state.globalUpgrades.speedTier;

        final currentProfitMult =
            1 + (profitTier * Economy.globalProfitTierBonus);
        final nextProfitMult =
            1 + ((profitTier + 1) * Economy.globalProfitTierBonus);
        final projectedProfitIncome =
            currentIncome * (nextProfitMult / currentProfitMult);

        final currentSpeedMult = 1 + (speedTier * Economy.globalSpeedTierBonus);
        final nextSpeedMult =
            1 + ((speedTier + 1) * Economy.globalSpeedTierBonus);
        final projectedSpeedIncome =
            currentIncome * (nextSpeedMult / currentSpeedMult);

        final globalProfitCost = Economy.globalProfitUpgradeCost(profitTier);
        final globalSpeedCost = Economy.globalSpeedUpgradeCost(speedTier);

        final unlockedStations = controller.stations
            .where((station) => station.isUnlocked)
            .toList();
        final stationIncomeById = <int, double>{
          for (final station in unlockedStations)
            station.definition.id: controller.stationIncomePerSecond(station),
        };

        var affordableActions = 0;
        var pendingActions = 0;
        var completedActions = 0;
        for (final station in unlockedStations) {
          final canBuyProfit =
              !station.hasProfitUpgrade &&
              controller.coins >= station.definition.profitUpgradeCost;
          final canBuyManager =
              !station.isAutomated &&
              controller.coins >= station.definition.managerCost;

          if (!station.hasProfitUpgrade) {
            pendingActions += 1;
          } else {
            completedActions += 1;
          }
          if (!station.isAutomated) {
            pendingActions += 1;
          } else {
            completedActions += 1;
          }
          if (canBuyProfit) {
            affordableActions += 1;
          }
          if (canBuyManager) {
            affordableActions += 1;
          }
        }
        final totalStationActions = unlockedStations.length * 2;
        final completionRatio = totalStationActions <= 0
            ? 0.0
            : (completedActions / totalStationActions)
                  .clamp(0.0, 1.0)
                  .toDouble();

        final recommendationCandidates = <_UpgradeRecommendation>[
          _UpgradeRecommendation(
            title: 'Global Profit Tier ${profitTier + 1}',
            subtitle:
                'Boosts all station earnings by ${(Economy.globalProfitTierBonus * 100).toStringAsFixed(0)}%',
            cost: globalProfitCost,
            incomeDelta: max(0.0, projectedProfitIncome - currentIncome),
            paybackSeconds: currentIncome > 0
                ? globalProfitCost /
                      max(0.0001, projectedProfitIncome - currentIncome)
                : double.infinity,
            affordable: controller.coins >= globalProfitCost,
            color: const Color(0xFF0EA5E9),
            onBuy: controller.buyGlobalProfitUpgrade,
          ),
          _UpgradeRecommendation(
            title: 'Global Speed Tier ${speedTier + 1}',
            subtitle:
                'Speeds up all cycles by ${(Economy.globalSpeedTierBonus * 100).toStringAsFixed(0)}%',
            cost: globalSpeedCost,
            incomeDelta: max(0.0, projectedSpeedIncome - currentIncome),
            paybackSeconds: currentIncome > 0
                ? globalSpeedCost /
                      max(0.0001, projectedSpeedIncome - currentIncome)
                : double.infinity,
            affordable: controller.coins >= globalSpeedCost,
            color: const Color(0xFF16A34A),
            onBuy: controller.buyGlobalSpeedUpgrade,
          ),
        ];

        for (final station in unlockedStations) {
          if (station.hasProfitUpgrade) {
            continue;
          }
          final stationIncome = stationIncomeById[station.definition.id] ?? 0.0;
          recommendationCandidates.add(
            _UpgradeRecommendation(
              title: 'Double ${station.definition.name} Profit',
              subtitle: 'Adds +${formatCoins(stationIncome)}/sec',
              cost: station.definition.profitUpgradeCost,
              incomeDelta: max(0.0, stationIncome),
              paybackSeconds: stationIncome > 0
                  ? station.definition.profitUpgradeCost / stationIncome
                  : double.infinity,
              affordable:
                  controller.coins >= station.definition.profitUpgradeCost,
              color: const Color(0xFF7C3AED),
              onBuy: () => controller.buyStationProfitUpgrade(station),
            ),
          );
        }

        final affordableCandidates =
            recommendationCandidates
                .where((candidate) => candidate.affordable)
                .toList()
              ..sort((a, b) {
                final paybackSort = a.paybackSeconds.compareTo(
                  b.paybackSeconds,
                );
                if (paybackSort != 0) {
                  return paybackSort;
                }
                return b.incomeDelta.compareTo(a.incomeDelta);
              });

        final fallbackCandidates = recommendationCandidates.toList()
          ..sort((a, b) {
            final aShortfall = max(0.0, a.cost - controller.coins);
            final bShortfall = max(0.0, b.cost - controller.coins);
            final shortfallSort = aShortfall.compareTo(bShortfall);
            if (shortfallSort != 0) {
              return shortfallSort;
            }
            return a.paybackSeconds.compareTo(b.paybackSeconds);
          });

        final recommended = affordableCandidates.isNotEmpty
            ? affordableCandidates.first
            : (fallbackCandidates.isNotEmpty ? fallbackCandidates.first : null);

        final sortedStations = [...unlockedStations]
          ..sort((a, b) {
            final aPending =
                (a.hasProfitUpgrade ? 0 : 1) + (a.isAutomated ? 0 : 1);
            final bPending =
                (b.hasProfitUpgrade ? 0 : 1) + (b.isAutomated ? 0 : 1);
            if (aPending != bPending) {
              return bPending.compareTo(aPending);
            }

            final aIncome = stationIncomeById[a.definition.id] ?? 0;
            final bIncome = stationIncomeById[b.definition.id] ?? 0;
            return bIncome.compareTo(aIncome);
          });

        final filteredStations = sortedStations.where((station) {
          switch (_filter) {
            case _UpgradeFilter.all:
              return true;
            case _UpgradeFilter.affordable:
              final canBuyProfit =
                  !station.hasProfitUpgrade &&
                  controller.coins >= station.definition.profitUpgradeCost;
              final canBuyManager =
                  !station.isAutomated &&
                  controller.coins >= station.definition.managerCost;
              return canBuyProfit || canBuyManager;
            case _UpgradeFilter.pending:
              return !station.hasProfitUpgrade || !station.isAutomated;
          }
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
          children: [
            const ArcadePanel(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              tint: Color(0xFF1E1B4B),
              child: Text(
                'RESEARCH LAB  Choose your next power spike',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _SummaryStrip(
              currentIncome: currentIncome,
              affordableActions: affordableActions,
              pendingActions: pendingActions,
              completionRatio: completionRatio,
              completedActions: completedActions,
              totalActions: totalStationActions,
            ),
            const SizedBox(height: 12),
            if (recommended != null) ...[
              _RecommendationCard(
                recommendation: recommended,
                coins: controller.coins,
              ),
              const SizedBox(height: 12),
            ],
            _QuickActionsCard(
              onAutoBuyProfit: () {
                final count = controller.buyAllAffordableProfitUpgrades();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      count > 0
                          ? 'Bought $count profit upgrade(s).'
                          : 'No affordable profit upgrades right now.',
                    ),
                  ),
                );
              },
              onAutoBuyManagers: () {
                final count = controller.buyAllAffordableManagers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      count > 0
                          ? 'Hired $count manager(s).'
                          : 'No affordable managers right now.',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Global Upgrades',
              child: Column(
                children: [
                  _UpgradeTile(
                    title:
                        'All Profits +${(Economy.globalProfitTierBonus * 100).toStringAsFixed(0)}%',
                    tierLabel: 'Tier $profitTier -> ${profitTier + 1}',
                    currentEffect: '${currentProfitMult.toStringAsFixed(2)}x',
                    nextEffect: '${nextProfitMult.toStringAsFixed(2)}x',
                    beforeIncome: currentIncome,
                    afterIncome: projectedProfitIncome,
                    cost: globalProfitCost,
                    coins: controller.coins,
                    color: const Color(0xFF0EA5E9),
                    enabled: controller.coins >= globalProfitCost,
                    onPressed: controller.buyGlobalProfitUpgrade,
                  ),
                  const SizedBox(height: 10),
                  _UpgradeTile(
                    title:
                        'All Speeds +${(Economy.globalSpeedTierBonus * 100).toStringAsFixed(0)}%',
                    tierLabel: 'Tier $speedTier -> ${speedTier + 1}',
                    currentEffect: '${currentSpeedMult.toStringAsFixed(2)}x',
                    nextEffect: '${nextSpeedMult.toStringAsFixed(2)}x',
                    beforeIncome: currentIncome,
                    afterIncome: projectedSpeedIncome,
                    cost: globalSpeedCost,
                    coins: controller.coins,
                    color: const Color(0xFF16A34A),
                    enabled: controller.coins >= globalSpeedCost,
                    onPressed: controller.buyGlobalSpeedUpgrade,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Per-Station Upgrades',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filter == _UpgradeFilter.all,
                        onTap: () =>
                            setState(() => _filter = _UpgradeFilter.all),
                      ),
                      _FilterChip(
                        label: 'Affordable',
                        selected: _filter == _UpgradeFilter.affordable,
                        onTap: () =>
                            setState(() => _filter = _UpgradeFilter.affordable),
                      ),
                      _FilterChip(
                        label: 'Pending',
                        selected: _filter == _UpgradeFilter.pending,
                        onTap: () =>
                            setState(() => _filter = _UpgradeFilter.pending),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (filteredStations.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No stations match this filter.',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  for (final station in filteredStations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StationUpgradeTile(
                        controller: controller,
                        station: station,
                        stationIncome:
                            stationIncomeById[station.definition.id] ?? 0,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.currentIncome,
    required this.affordableActions,
    required this.pendingActions,
    required this.completionRatio,
    required this.completedActions,
    required this.totalActions,
  });

  final double currentIncome;
  final int affordableActions;
  final int pendingActions;
  final double completionRatio;
  final int completedActions;
  final int totalActions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Income/sec',
                value: formatCoins(currentIncome),
                color: const Color(0xFF22D3EE),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                label: 'Affordable',
                value: '$affordableActions',
                color: const Color(0xFF4ADE80),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                label: 'Pending',
                value: '$pendingActions',
                color: const Color(0xFFFACC15),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upgrade Completion: $completedActions / $totalActions',
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: completionRatio,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF22D3EE),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeRecommendation {
  const _UpgradeRecommendation({
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.incomeDelta,
    required this.paybackSeconds,
    required this.affordable,
    required this.color,
    required this.onBuy,
  });

  final String title;
  final String subtitle;
  final double cost;
  final double incomeDelta;
  final double paybackSeconds;
  final bool affordable;
  final Color color;
  final VoidCallback onBuy;
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.coins,
  });

  final _UpgradeRecommendation recommendation;
  final double coins;

  @override
  Widget build(BuildContext context) {
    final shortfall = max(0.0, recommendation.cost - coins);
    final eta = _formatEta(recommendation.paybackSeconds);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: recommendation.color.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Next Buy',
            style: TextStyle(
              color: Color(0xFFBFDBFE),
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            recommendation.title,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            recommendation.subtitle,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _infoPill(
                  'Gain +${formatCoins(recommendation.incomeDelta)}/s',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _infoPill('Payback $eta')),
            ],
          ),
          if (!recommendation.affordable) ...[
            const SizedBox(height: 6),
            Text(
              'Need ${formatCoins(shortfall)} more coins',
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 10),
          PurchaseButton(
            label: 'Buy ${formatCoins(recommendation.cost)}',
            enabled: recommendation.affordable,
            backgroundColor: recommendation.color,
            onPressed: recommendation.affordable ? recommendation.onBuy : null,
          ),
        ],
      ),
    );
  }

  Widget _infoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFBFDBFE),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  String _formatEta(double seconds) {
    if (seconds.isInfinite || seconds.isNaN || seconds <= 0) {
      return 'N/A';
    }
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(0)}s';
    }
    if (seconds < 3600) {
      return '${(seconds / 60).toStringAsFixed(1)}m';
    }
    return '${(seconds / 3600).toStringAsFixed(1)}h';
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onAutoBuyProfit,
    required this.onAutoBuyManagers,
  });

  final VoidCallback onAutoBuyProfit;
  final VoidCallback onAutoBuyManagers;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Color(0xFFF8FAFC),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'One tap to apply all affordable upgrades in bulk.',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PurchaseButton(
                  label: 'Auto-Buy Profit x2',
                  backgroundColor: const Color(0xFF7C3AED),
                  onPressed: onAutoBuyProfit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PurchaseButton(
                  label: 'Auto-Hire Managers',
                  backgroundColor: const Color(0xFF16A34A),
                  onPressed: onAutoBuyManagers,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
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
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFFF8FAFC),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _UpgradeTile extends StatelessWidget {
  const _UpgradeTile({
    required this.title,
    required this.tierLabel,
    required this.currentEffect,
    required this.nextEffect,
    required this.beforeIncome,
    required this.afterIncome,
    required this.cost,
    required this.coins,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final String title;
  final String tierLabel;
  final String currentEffect;
  final String nextEffect;
  final double beforeIncome;
  final double afterIncome;
  final double cost;
  final double coins;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final shortfall = max(0.0, cost - coins);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF334155).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                    color: Color(0xFFF8FAFC),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: color.withValues(alpha: 0.2),
                ),
                child: Text(
                  tierLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Effect: $currentEffect -> $nextEffect',
            style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
          ),
          Text(
            'Income/sec: ${formatCoins(beforeIncome)} -> ${formatCoins(afterIncome)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
          ),
          if (!enabled)
            Text(
              'Need ${formatCoins(shortfall)} more coins',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFFCA5A5),
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 10),
          PurchaseButton(
            label: 'Buy ${formatCoins(cost)}',
            backgroundColor: color,
            enabled: enabled,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? const Color(0xFF0EA5E9).withValues(alpha: 0.26)
              : const Color(0xFF334155).withValues(alpha: 0.45),
          border: Border.all(
            color: selected
                ? const Color(0xFF38BDF8)
                : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        child: Text(
          label,
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

class _StationUpgradeTile extends StatelessWidget {
  const _StationUpgradeTile({
    required this.controller,
    required this.station,
    required this.stationIncome,
  });

  final GameController controller;
  final Station station;
  final double stationIncome;

  @override
  Widget build(BuildContext context) {
    final profitBought = station.hasProfitUpgrade;
    final managerBought = station.isAutomated;

    final profitCost = station.definition.profitUpgradeCost;
    final managerCost = station.definition.managerCost;

    final canAffordProfit = !profitBought && controller.coins >= profitCost;
    final canAffordManager = !managerBought && controller.coins >= managerCost;

    final profitShortfall = max(0.0, profitCost - controller.coins);
    final managerShortfall = max(0.0, managerCost - controller.coins);

    final profitGain = profitBought ? 0.0 : stationIncome;
    final paybackSeconds = profitGain > 0 ? profitCost / profitGain : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF334155).withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${station.definition.icon}  ${station.definition.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF8FAFC),
                  ),
                ),
              ),
              _StatePill(
                label: profitBought ? 'Profit x2' : 'Profit Base',
                active: profitBought,
                activeColor: const Color(0xFFA78BFA),
              ),
              const SizedBox(width: 6),
              _StatePill(
                label: managerBought ? 'Auto ON' : 'Manual',
                active: managerBought,
                activeColor: const Color(0xFF4ADE80),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Income/sec: ${formatCoins(stationIncome)}',
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
          ),
          if (!profitBought)
            Text(
              'Double-profit payback: ${_formatEta(paybackSeconds)}',
              style: const TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 10),
          PurchaseButton(
            label: profitBought
                ? 'Double Profit Installed'
                : canAffordProfit
                ? 'Double Profit  (${formatCoins(profitCost)})'
                : 'Need ${formatCoins(profitShortfall)} for Profit x2',
            enabled: !profitBought && canAffordProfit,
            backgroundColor: const Color(0xFF7C3AED),
            onPressed: profitBought
                ? null
                : () => controller.buyStationProfitUpgrade(station),
          ),
          const SizedBox(height: 8),
          PurchaseButton(
            label: managerBought
                ? 'Manager Active'
                : canAffordManager
                ? 'Hire Manager  (${formatCoins(managerCost)})'
                : 'Need ${formatCoins(managerShortfall)} for Manager',
            enabled: !managerBought && canAffordManager,
            backgroundColor: const Color(0xFF16A34A),
            onPressed: managerBought
                ? null
                : () => controller.buyStationManager(station),
          ),
        ],
      ),
    );
  }

  String _formatEta(double seconds) {
    if (seconds <= 0 || seconds.isInfinite || seconds.isNaN) {
      return 'N/A';
    }
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(0)}s';
    }
    if (seconds < 3600) {
      return '${(seconds / 60).toStringAsFixed(1)}m';
    }
    return '${(seconds / 3600).toStringAsFixed(1)}h';
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({
    required this.label,
    required this.active,
    required this.activeColor,
  });

  final String label;
  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: active ? 0.22 : 0.14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
