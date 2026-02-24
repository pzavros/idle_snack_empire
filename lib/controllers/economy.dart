import 'dart:math';

import '../models/game_state.dart';
import '../models/station.dart';

class Economy {
  static const double maxOfflineSeconds = 12 * 60 * 60;
  static const double basePrestigeThreshold = 1000000;
  static const double prestigeThresholdGrowth = 2.0;
  static const double globalProfitTierBonus = 0.12;
  static const double globalSpeedTierBonus = 0.08;

  static double levelUpCost(Station station) {
    return station.definition.baseCost * pow(1.18, station.level);
  }

  static double globalProfitUpgradeCost(int currentTier) {
    return (420 * pow(2.05, currentTier)).toDouble();
  }

  static double globalSpeedUpgradeCost(int currentTier) {
    return (550 * pow(2.12, currentTier)).toDouble();
  }

  static double globalProfitMultiplier(GameState state) {
    return 1 + (state.globalUpgrades.profitTier * globalProfitTierBonus);
  }

  static double globalSpeedMultiplier(GameState state) {
    return 1 + (state.globalUpgrades.speedTier * globalSpeedTierBonus);
  }

  static double permanentMultiplier(GameState state) {
    return 1 + (state.empireLevel * 0.5);
  }

  static bool isDoubleIncomeBoostActive(GameState state, int nowEpochMs) {
    return state.boost2xEndEpochMs > nowEpochMs;
  }

  static double activeBoostMultiplier(GameState state, int nowEpochMs) {
    return isDoubleIncomeBoostActive(state, nowEpochMs) ? 2 : 1;
  }

  static double stationProfitPerCycle(
    Station station,
    GameState state, {
    required int nowEpochMs,
    bool includeBoost = true,
  }) {
    if (!station.isUnlocked || station.level <= 0) {
      return 0;
    }

    final globalProfit = globalProfitMultiplier(state);
    final permanent = permanentMultiplier(state);
    final boost = includeBoost ? activeBoostMultiplier(state, nowEpochMs) : 1;
    return station.baseProfitPerCycle() * globalProfit * permanent * boost;
  }

  static double stationIncomePerSecond(
    Station station,
    GameState state, {
    required int nowEpochMs,
    bool includeBoost = true,
  }) {
    if (!station.isUnlocked || station.level <= 0) {
      return 0;
    }

    final duration = station.effectiveCycleSeconds(
      globalSpeedMultiplier(state),
    );
    if (duration <= 0) {
      return 0;
    }

    final cycleProfit = stationProfitPerCycle(
      station,
      state,
      nowEpochMs: nowEpochMs,
      includeBoost: includeBoost,
    );
    return cycleProfit / duration;
  }

  static double totalIncomePerSecond(
    List<Station> stations,
    GameState state, {
    required int nowEpochMs,
    bool includeBoost = true,
  }) {
    var total = 0.0;
    for (final station in stations) {
      total += stationIncomePerSecond(
        station,
        state,
        nowEpochMs: nowEpochMs,
        includeBoost: includeBoost,
      );
    }
    return total;
  }

  static double prestigeThresholdForCount(int prestigeCount) {
    final safeCount = max(0, prestigeCount);
    return (basePrestigeThreshold * pow(prestigeThresholdGrowth, safeCount))
        .toDouble();
  }

  static int estimatePrestigeGain({
    required double runCoinsSincePrestige,
    required int prestigeCount,
  }) {
    final threshold = prestigeThresholdForCount(prestigeCount);
    if (runCoinsSincePrestige < threshold) {
      return 0;
    }

    final ratio = max(1.0, runCoinsSincePrestige / threshold);
    return 1 + (log(ratio) / ln2).floor();
  }
}
