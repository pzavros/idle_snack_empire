enum RewardedPlacement {
  incomeBoost,
  instantCash,
  tycoonBundle,
  offlineDouble,
  jackpotCrate,
}

abstract class AdsService {
  Future<bool> showRewarded(RewardedPlacement placement);
  Future<void> showInterstitial();
}

class StubAdsService implements AdsService {
  StubAdsService({
    this.rewardedResult = true,
    this.simulatedDelay = const Duration(milliseconds: 600),
  });

  final bool rewardedResult;
  final Duration simulatedDelay;

  @override
  Future<bool> showRewarded(RewardedPlacement placement) async {
    await Future<void>.delayed(simulatedDelay);
    return rewardedResult;
  }

  @override
  Future<void> showInterstitial() async {
    await Future<void>.delayed(simulatedDelay);
  }
}
