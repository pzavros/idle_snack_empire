class OfflineEarningsResult {
  const OfflineEarningsResult({
    required this.awaySeconds,
    required this.baseCoins,
    required this.computedAtEpochMs,
  });

  final int awaySeconds;
  final double baseCoins;
  final int computedAtEpochMs;

  Duration get awayDuration => Duration(seconds: awaySeconds);
}

class OfflineEarningsCalculator {
  static OfflineEarningsResult? calculate({
    required int lastSavedEpochMs,
    required int nowEpochMs,
    required double incomePerSecond,
    required double offlineMultiplier,
    required int maxSeconds,
  }) {
    if (lastSavedEpochMs <= 0 || nowEpochMs <= lastSavedEpochMs) {
      return null;
    }

    final elapsedSeconds = ((nowEpochMs - lastSavedEpochMs) / 1000).floor();
    if (elapsedSeconds <= 5 || incomePerSecond <= 0) {
      return null;
    }

    final clampedSeconds = elapsedSeconds.clamp(0, maxSeconds);
    final baseCoins = clampedSeconds * incomePerSecond * offlineMultiplier;

    if (baseCoins <= 0) {
      return null;
    }

    return OfflineEarningsResult(
      awaySeconds: clampedSeconds,
      baseCoins: baseCoins,
      computedAtEpochMs: nowEpochMs,
    );
  }
}
