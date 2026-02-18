import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/station.dart';
import '../models/upgrades.dart';
import '../services/ads_service.dart';
import '../services/haptics_service.dart';
import '../services/storage_service.dart';
import 'economy.dart';
import 'offline_earnings.dart';

class CoinParticleEvent {
  const CoinParticleEvent({
    required this.id,
    required this.origin,
    required this.amount,
  });

  final int id;
  final Offset origin;
  final double amount;
}

class GameMomentEvent {
  const GameMomentEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final int id;
  final String title;
  final String subtitle;
  final Color color;
}

class GameController extends ChangeNotifier {
  GameController({
    required StorageService storageService,
    required AdsService adsService,
    required HapticsService hapticsService,
  }) : _storageService = storageService,
       _adsService = adsService,
       _hapticsService = hapticsService;

  static const int _stationsPerStage = 2;
  static const List<String> _stageNames = [
    'Street Stall Strip',
    'Food Truck Block',
    'Downtown Kitchens',
    'Mall Food Court',
    'Festival Plaza',
    'Skyline District',
    'Orbital Terminal',
  ];

  final StorageService _storageService;
  final AdsService _adsService;
  final HapticsService _hapticsService;

  final ValueNotifier<List<CoinParticleEvent>> coinParticleEvents =
      ValueNotifier<List<CoinParticleEvent>>(<CoinParticleEvent>[]);
  final ValueNotifier<List<GameMomentEvent>> gameMomentEvents =
      ValueNotifier<List<GameMomentEvent>>(<GameMomentEvent>[]);

  late GameState _state;
  List<Station> _stations = <Station>[];

  Timer? _tickTimer;
  Timer? _autosaveTimer;
  DateTime _lastTickTime = DateTime.now();

  OfflineEarningsResult? _pendingOfflineEarnings;

  int _particleIdCounter = 0;
  int _momentIdCounter = 0;
  int _lastBoostRemainingSecond = -1;
  int _lastAutoParticleEpochMs = 0;
  int _collectCombo = 0;
  int _lastManualCollectEpochMs = 0;
  bool _ready = false;

  bool get isReady => _ready;
  GameState get state => _state;
  List<Station> get stations => _stations;
  OfflineEarningsResult? get pendingOfflineEarnings => _pendingOfflineEarnings;

  double get coins => _state.coins;
  double get lifetimeCoins => _state.lifetimeCoins;
  double get runCoinsSincePrestige => _state.lifetimeCoinsSincePrestige;
  int get goldenChips => _state.goldenChips;
  int get prestigeCount => _state.prestigeCount;
  double get currentGlobalSpeedMultiplier =>
      Economy.globalSpeedMultiplier(_state);

  ThemePalette get selectedTheme {
    return kThemePalettes.firstWhere(
      (theme) => theme.id == _state.selectedTheme,
      orElse: () => kThemePalettes.first,
    );
  }

  AvatarOption get selectedAvatar {
    return kAvatarOptions.firstWhere(
      (avatar) => avatar.id == _state.selectedAvatar,
      orElse: () => kAvatarOptions.first,
    );
  }

  bool get hasActiveDoubleBoost {
    final nowEpochMs = DateTime.now().millisecondsSinceEpoch;
    return Economy.isDoubleIncomeBoostActive(_state, nowEpochMs);
  }

  Duration get activeDoubleBoostRemaining {
    final nowEpochMs = DateTime.now().millisecondsSinceEpoch;
    final seconds = max(
      0,
      ((_state.boost2xEndEpochMs - nowEpochMs) / 1000).ceil(),
    );
    return Duration(seconds: seconds);
  }

  double get permanentIncomeMultiplier => Economy.permanentMultiplier(_state);

  double get incomePerSecond {
    final nowEpochMs = DateTime.now().millisecondsSinceEpoch;
    return Economy.totalIncomePerSecond(
      _stations,
      _state,
      nowEpochMs: nowEpochMs,
      includeBoost: true,
    );
  }

  double get nextPrestigeThreshold =>
      Economy.prestigeThresholdForCount(_state.prestigeCount);

  double get prestigeProgress => (runCoinsSincePrestige / nextPrestigeThreshold)
      .clamp(0.0, 1.0)
      .toDouble();

  bool get canPrestige => runCoinsSincePrestige >= nextPrestigeThreshold;
  int get collectCombo => _collectCombo;
  double get comboBonusMultiplier =>
      _collectCombo <= 1 ? 1 : 1 + min(0.45, (_collectCombo - 1) * 0.05);

  int get totalStages =>
      (kStationDefinitions.length / _stationsPerStage).ceil();

  int get highestUnlockedStationId {
    for (var index = _stations.length - 1; index >= 0; index -= 1) {
      if (_stations[index].isUnlocked) {
        return _stations[index].definition.id;
      }
    }
    return 0;
  }

  int get currentStageIndex {
    if (_stations.isEmpty) {
      return 0;
    }
    return (highestUnlockedStationId ~/ _stationsPerStage).clamp(
      0,
      totalStages - 1,
    );
  }

  String get currentStageLabel => 'Stage ${currentStageIndex + 1}/$totalStages';

  String get currentStageName {
    if (currentStageIndex < _stageNames.length) {
      return _stageNames[currentStageIndex];
    }
    return 'Zone ${currentStageIndex + 1}';
  }

  double get currentStageProgress {
    if (_stations.isEmpty) {
      return 0;
    }

    final start = currentStageIndex * _stationsPerStage;
    final end = min(start + _stationsPerStage, _stations.length);
    final count = end - start;
    if (count <= 0) {
      return 0;
    }

    var unlockedInStage = 0;
    for (var i = start; i < end; i += 1) {
      if (_stations[i].isUnlocked) {
        unlockedInStage += 1;
      }
    }

    return (unlockedInStage / count).clamp(0.0, 1.0).toDouble();
  }

  double? get nextStageUnlockCost {
    final nextStageStart = (currentStageIndex + 1) * _stationsPerStage;
    if (nextStageStart >= _stations.length) {
      return null;
    }
    return _stations[nextStageStart].definition.unlockCost;
  }

  int get estimatedPrestigeGain => Economy.estimatePrestigeGain(
    runCoinsSincePrestige: runCoinsSincePrestige,
    prestigeCount: _state.prestigeCount,
  );

  Future<void> initialize() async {
    if (_ready) {
      return;
    }

    _state = await _storageService.loadGameState();
    _rebuildStationsFromState();
    _normalizeState();

    _ready = true;
    _lastTickTime = DateTime.now();
    _tryCreateOfflineEarnings();
    _startRuntimeLoops();
    _refreshBestIncomePerSecond();
    notifyListeners();
  }

  void _normalizeState() {
    if (!_state.unlockedThemes.contains(0)) {
      _state.unlockedThemes.add(0);
    }
    if (!_state.unlockedAvatars.contains(0)) {
      _state.unlockedAvatars.add(0);
    }

    final validTheme = kThemePalettes.any(
      (theme) => theme.id == _state.selectedTheme,
    );
    if (!validTheme) {
      _state.selectedTheme = 0;
    }

    final validAvatar = kAvatarOptions.any(
      (avatar) => avatar.id == _state.selectedAvatar,
    );
    if (!validAvatar) {
      _state.selectedAvatar = 0;
    }

    if (!_state.unlockedThemes.contains(_state.selectedTheme)) {
      _state.selectedTheme = 0;
    }
    if (!_state.unlockedAvatars.contains(_state.selectedAvatar)) {
      _state.selectedAvatar = 0;
    }

    if (_state.lastSavedEpochMs <= 0) {
      _state.lastSavedEpochMs = DateTime.now().millisecondsSinceEpoch;
    }
    if (_state.lifetimeCoinsSincePrestige < 0) {
      _state.lifetimeCoinsSincePrestige = 0;
    }
    if (_state.prestigeCount < 0) {
      _state.prestigeCount = 0;
    }
  }

  void _rebuildStationsFromState() {
    final byId = <int, StationData>{
      for (final stationData in _state.stations) stationData.id: stationData,
    };

    final normalizedStationData = <StationData>[];
    final rebuiltStations = <Station>[];

    for (final definition in kStationDefinitions) {
      final stationData =
          byId[definition.id] ??
          StationData.initial(id: definition.id, unlocked: definition.id == 0);
      normalizedStationData.add(stationData);
      rebuiltStations.add(Station(definition: definition, data: stationData));
    }

    _state.stations = normalizedStationData;
    _stations = rebuiltStations;
  }

  void _startRuntimeLoops() {
    _tickTimer?.cancel();
    _autosaveTimer?.cancel();

    _tickTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _handleTick(),
    );

    _autosaveTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => saveNow(),
    );
  }

  void _stopRuntimeLoops() {
    _tickTimer?.cancel();
    _autosaveTimer?.cancel();
    _tickTimer = null;
    _autosaveTimer = null;
  }

  void _handleTick() {
    if (!_ready) {
      return;
    }

    final now = DateTime.now();
    final elapsedSeconds =
        (now.millisecondsSinceEpoch - _lastTickTime.millisecondsSinceEpoch) /
        1000;

    if (elapsedSeconds <= 0) {
      return;
    }

    _lastTickTime = now;

    final nowEpochMs = now.millisecondsSinceEpoch;
    final speedMultiplier = Economy.globalSpeedMultiplier(_state);
    var autoCollectedCoins = 0.0;

    for (final station in _stations) {
      final completedCycles = station.advance(
        elapsedSeconds: elapsedSeconds,
        globalSpeedMultiplier: speedMultiplier,
        nowEpochMs: nowEpochMs,
      );

      if (completedCycles > 0) {
        autoCollectedCoins +=
            completedCycles *
            Economy.stationProfitPerCycle(
              station,
              _state,
              nowEpochMs: nowEpochMs,
            );
      }
    }

    var shouldNotify = false;

    if (autoCollectedCoins > 0) {
      _addCoins(autoCollectedCoins);
      if (nowEpochMs - _lastAutoParticleEpochMs > 900) {
        _lastAutoParticleEpochMs = nowEpochMs;
        _spawnCoinParticle(
          origin: const Offset(120, 120),
          amount: autoCollectedCoins,
        );
      }
      shouldNotify = true;
    }

    if (hasActiveDoubleBoost) {
      final remaining = activeDoubleBoostRemaining.inSeconds;
      if (remaining != _lastBoostRemainingSecond) {
        _lastBoostRemainingSecond = remaining;
        shouldNotify = true;
      }
    } else if (_lastBoostRemainingSecond != -1) {
      _lastBoostRemainingSecond = -1;
      shouldNotify = true;
    }

    if (_refreshBestIncomePerSecond()) {
      shouldNotify = true;
    }

    if (_collectCombo > 0 && nowEpochMs - _lastManualCollectEpochMs > 3500) {
      _collectCombo = 0;
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  bool _refreshBestIncomePerSecond() {
    final current = incomePerSecond;
    if (current > _state.highestIncomePerSecond) {
      _state.highestIncomePerSecond = current;
      return true;
    }
    return false;
  }

  void _addCoins(double amount) {
    if (amount <= 0) {
      return;
    }
    _state.coins += amount;
    _state.lifetimeCoins += amount;
    _state.lifetimeCoinsSincePrestige += amount;
    if (_state.coins > _state.highestCoins) {
      _state.highestCoins = _state.coins;
    }
  }

  bool _spendCoins(double amount) {
    if (amount <= 0 || _state.coins < amount) {
      return false;
    }
    _state.coins -= amount;
    return true;
  }

  double levelUpCostForStation(Station station) => Economy.levelUpCost(station);

  double stationProfitPerCycle(Station station) {
    final nowEpochMs = DateTime.now().millisecondsSinceEpoch;
    return Economy.stationProfitPerCycle(
      station,
      _state,
      nowEpochMs: nowEpochMs,
      includeBoost: true,
    );
  }

  double stationIncomePerSecond(Station station) {
    final nowEpochMs = DateTime.now().millisecondsSinceEpoch;
    return Economy.stationIncomePerSecond(
      station,
      _state,
      nowEpochMs: nowEpochMs,
      includeBoost: true,
    );
  }

  int requiredPreviousLevelForUnlock(Station station) {
    if (station.definition.id == 0) {
      return 0;
    }
    final stationStage = station.definition.id ~/ _stationsPerStage;
    return 8 + (stationStage * 5);
  }

  bool meetsUnlockLevelRequirement(Station station) {
    if (station.definition.id == 0) {
      return true;
    }
    final previousId = station.definition.id - 1;
    if (previousId < 0 || previousId >= _stations.length) {
      return false;
    }
    final previousStation = _stations[previousId];
    return previousStation.level >= requiredPreviousLevelForUnlock(station);
  }

  bool canUnlockStation(Station station) {
    if (station.isUnlocked) {
      return false;
    }
    if (coins < station.definition.unlockCost) {
      return false;
    }
    return meetsUnlockLevelRequirement(station);
  }

  String unlockRequirementDescription(Station station) {
    if (station.definition.id == 0) {
      return 'Starter Station';
    }
    final previousId = station.definition.id - 1;
    if (previousId < 0 || previousId >= _stations.length) {
      return 'Complete previous station requirements';
    }
    final previousStation = _stations[previousId];
    final requiredLevel = requiredPreviousLevelForUnlock(station);
    if (previousStation.level >= requiredLevel) {
      return '${previousStation.definition.name} Lv.$requiredLevel met';
    }
    return '${previousStation.definition.name} needs Lv.$requiredLevel '
        '(current Lv.${previousStation.level})';
  }

  bool unlockStation(Station station) {
    if (!canUnlockStation(station)) {
      return false;
    }
    if (!_spendCoins(station.definition.unlockCost)) {
      return false;
    }

    station.unlock();
    _registerMajorAction();
    _emitMoment(
      title: '${station.definition.icon} New Station',
      subtitle: station.definition.name,
      color: controllerColorSky,
    );
    unawaited(_hapticsService.medium(enabled: _state.hapticsEnabled));
    notifyListeners();
    return true;
  }

  bool buyStationLevel(Station station) {
    if (!station.isUnlocked) {
      return false;
    }
    final cost = levelUpCostForStation(station);
    if (!_spendCoins(cost)) {
      return false;
    }

    station.levelUp();
    _registerMajorAction();
    if (station.level % 10 == 0) {
      _emitMoment(
        title: 'Level ${station.level}',
        subtitle: '${station.definition.name} milestone',
        color: controllerColorGold,
      );
    }
    unawaited(_hapticsService.medium(enabled: _state.hapticsEnabled));
    notifyListeners();
    return true;
  }

  bool buyStationManager(Station station) {
    if (!station.isUnlocked || station.isAutomated) {
      return false;
    }
    if (!_spendCoins(station.definition.managerCost)) {
      return false;
    }

    station.enableAutomation();
    _registerMajorAction();
    _emitMoment(
      title: 'Manager Hired',
      subtitle: '${station.definition.name} is now automated',
      color: controllerColorMint,
    );
    unawaited(_hapticsService.medium(enabled: _state.hapticsEnabled));
    notifyListeners();
    return true;
  }

  bool buyStationProfitUpgrade(Station station) {
    if (!station.isUnlocked || station.hasProfitUpgrade) {
      return false;
    }
    if (!_spendCoins(station.definition.profitUpgradeCost)) {
      return false;
    }

    station.applyProfitUpgrade();
    _registerMajorAction();
    _emitMoment(
      title: 'Profit Doubled',
      subtitle: station.definition.name,
      color: controllerColorViolet,
    );
    unawaited(_hapticsService.medium(enabled: _state.hapticsEnabled));
    notifyListeners();
    return true;
  }

  bool collectStation(Station station, {Offset? particleOrigin}) {
    final cycles = station.collectPendingCycles();
    if (cycles <= 0) {
      return false;
    }

    final nowEpochMs = DateTime.now().millisecondsSinceEpoch;
    final withinComboWindow = nowEpochMs - _lastManualCollectEpochMs <= 3500;
    _collectCombo = withinComboWindow
        ? (_collectCombo + 1).clamp(1, 20).toInt()
        : 1;
    _lastManualCollectEpochMs = nowEpochMs;

    final gain =
        cycles *
        Economy.stationProfitPerCycle(
          station,
          _state,
          nowEpochMs: nowEpochMs,
          includeBoost: true,
        ) *
        comboBonusMultiplier;

    _addCoins(gain);
    final origin = particleOrigin ?? const Offset(180, 280);
    _spawnCoinParticle(origin: origin, amount: gain);
    if (_collectCombo >= 3) {
      _spawnCoinParticle(origin: origin.translate(28, -10), amount: gain * 0.2);
      _spawnCoinParticle(
        origin: origin.translate(-22, -6),
        amount: gain * 0.18,
      );
      if (_collectCombo % 3 == 0) {
        _emitMoment(
          title: 'Combo x$_collectCombo',
          subtitle:
              '+${((comboBonusMultiplier - 1) * 100).toStringAsFixed(0)}% collect bonus',
          color: controllerColorGold,
        );
        unawaited(_hapticsService.medium(enabled: _state.hapticsEnabled));
      }
    }
    unawaited(_hapticsService.light(enabled: _state.hapticsEnabled));

    notifyListeners();
    return true;
  }

  bool buyGlobalProfitUpgrade() {
    final cost = Economy.globalProfitUpgradeCost(
      _state.globalUpgrades.profitTier,
    );
    if (!_spendCoins(cost)) {
      return false;
    }

    _state.globalUpgrades.profitTier += 1;
    _registerMajorAction();
    _emitMoment(
      title: 'Global Profit Up',
      subtitle: 'All stations earn more',
      color: controllerColorSky,
    );
    unawaited(_hapticsService.medium(enabled: _state.hapticsEnabled));
    notifyListeners();
    return true;
  }

  bool buyGlobalSpeedUpgrade() {
    final cost = Economy.globalSpeedUpgradeCost(
      _state.globalUpgrades.speedTier,
    );
    if (!_spendCoins(cost)) {
      return false;
    }

    _state.globalUpgrades.speedTier += 1;
    _registerMajorAction();
    _emitMoment(
      title: 'Global Speed Up',
      subtitle: 'All cycles complete faster',
      color: controllerColorMint,
    );
    unawaited(_hapticsService.medium(enabled: _state.hapticsEnabled));
    notifyListeners();
    return true;
  }

  void registerShopOpened() {
    _state.shopOpenCount += 1;
    if (_state.shopOpenCount % 4 == 0) {
      unawaited(_adsService.showInterstitial());
    }
  }

  bool buyDoubleIncomeBoostWithCoins() {
    const cost = 500.0;
    if (!_spendCoins(cost)) {
      return false;
    }

    _activateDoubleIncomeBoost(const Duration(minutes: 15));
    _registerMajorAction();
    _emitMoment(
      title: '2x Income Active',
      subtitle: '15 minute boost started',
      color: controllerColorSky,
    );
    notifyListeners();
    return true;
  }

  Future<bool> watchAdForDoubleIncomeBoost() async {
    final rewarded = await _adsService.showRewarded();
    if (!rewarded) {
      return false;
    }

    _activateDoubleIncomeBoost(const Duration(minutes: 15));
    _emitMoment(
      title: '2x Income Active',
      subtitle: 'Rewarded boost started',
      color: controllerColorSky,
    );
    notifyListeners();
    return true;
  }

  bool buyInstantIncomePack() {
    const cost = 300.0;
    if (!_spendCoins(cost)) {
      return false;
    }

    _grantInstantIncome(minutes: 5);
    _registerMajorAction();
    _emitMoment(
      title: 'Cash Surge',
      subtitle: 'You claimed 5 minutes instantly',
      color: controllerColorMint,
    );
    notifyListeners();
    return true;
  }

  Future<bool> watchAdForInstantIncome() async {
    final rewarded = await _adsService.showRewarded();
    if (!rewarded) {
      return false;
    }

    _grantInstantIncome(minutes: 5);
    _emitMoment(
      title: 'Cash Surge',
      subtitle: 'Rewarded instant income granted',
      color: controllerColorMint,
    );
    notifyListeners();
    return true;
  }

  void _grantInstantIncome({required int minutes}) {
    final gain = incomePerSecond * minutes * 60;
    if (gain <= 0) {
      return;
    }
    _addCoins(gain);
    _spawnCoinParticle(origin: const Offset(220, 220), amount: gain);
  }

  void _activateDoubleIncomeBoost(Duration duration) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final baseline = max(now, _state.boost2xEndEpochMs);
    _state.boost2xEndEpochMs = baseline + duration.inMilliseconds;
  }

  void _registerMajorAction() {
    _state.majorActionCount += 1;
    if (_state.majorActionCount % 5 == 0) {
      unawaited(_adsService.showInterstitial());
    }
  }

  bool unlockTheme(ThemePalette theme) {
    if (_state.unlockedThemes.contains(theme.id)) {
      return true;
    }
    if (!_spendCoins(theme.unlockCost)) {
      return false;
    }

    _state.unlockedThemes.add(theme.id);
    _registerMajorAction();
    _emitMoment(
      title: 'Theme Unlocked',
      subtitle: theme.name,
      color: controllerColorViolet,
    );
    notifyListeners();
    return true;
  }

  void selectTheme(int themeId) {
    if (!_state.unlockedThemes.contains(themeId)) {
      return;
    }
    _state.selectedTheme = themeId;
    notifyListeners();
  }

  bool unlockAvatar(AvatarOption avatar) {
    if (_state.unlockedAvatars.contains(avatar.id)) {
      return true;
    }
    if (!_spendCoins(avatar.unlockCost)) {
      return false;
    }

    _state.unlockedAvatars.add(avatar.id);
    _registerMajorAction();
    _emitMoment(
      title: 'Avatar Unlocked',
      subtitle: avatar.name,
      color: controllerColorViolet,
    );
    notifyListeners();
    return true;
  }

  void selectAvatar(int avatarId) {
    if (!_state.unlockedAvatars.contains(avatarId)) {
      return;
    }
    _state.selectedAvatar = avatarId;
    notifyListeners();
  }

  void setSoundEnabled(bool enabled) {
    _state.soundEnabled = enabled;
    notifyListeners();
  }

  void setHapticsEnabled(bool enabled) {
    _state.hapticsEnabled = enabled;
    notifyListeners();
  }

  bool isThemeUnlocked(int themeId) => _state.unlockedThemes.contains(themeId);

  bool isAvatarUnlocked(int avatarId) =>
      _state.unlockedAvatars.contains(avatarId);

  void _tryCreateOfflineEarnings() {
    final nowEpochMs = DateTime.now().millisecondsSinceEpoch;
    final baselineIncomePerSecond = Economy.totalIncomePerSecond(
      _stations,
      _state,
      nowEpochMs: nowEpochMs,
      includeBoost: false,
    );

    _pendingOfflineEarnings = OfflineEarningsCalculator.calculate(
      lastSavedEpochMs: _state.lastSavedEpochMs,
      nowEpochMs: nowEpochMs,
      incomePerSecond: baselineIncomePerSecond,
      offlineMultiplier: 1,
      maxSeconds: Economy.maxOfflineSeconds.toInt(),
    );
  }

  double collectOfflineEarnings({required bool doubled}) {
    final pending = _pendingOfflineEarnings;
    if (pending == null) {
      return 0;
    }

    final multiplier = doubled ? 2.0 : 1.0;
    final amount = pending.baseCoins * multiplier;
    _addCoins(amount);
    _pendingOfflineEarnings = null;

    _spawnCoinParticle(origin: const Offset(200, 260), amount: amount);
    _emitMoment(
      title: doubled ? 'Offline 2x Claim' : 'Offline Claim',
      subtitle: '+${amount.toStringAsFixed(0)} coins',
      color: controllerColorSky,
    );
    notifyListeners();
    return amount;
  }

  Future<double> collectOfflineEarningsWithRewardedDouble() async {
    final pending = _pendingOfflineEarnings;
    if (pending == null) {
      return 0;
    }

    final rewarded = await _adsService.showRewarded();
    if (!rewarded) {
      return 0;
    }

    return collectOfflineEarnings(doubled: true);
  }

  void dismissOfflineEarnings() {
    _pendingOfflineEarnings = null;
    notifyListeners();
  }

  void _spawnCoinParticle({required Offset origin, required double amount}) {
    final event = CoinParticleEvent(
      id: ++_particleIdCounter,
      origin: origin,
      amount: amount,
    );

    coinParticleEvents.value = <CoinParticleEvent>[
      ...coinParticleEvents.value,
      event,
    ];
  }

  void removeCoinParticle(int id) {
    coinParticleEvents.value = coinParticleEvents.value
        .where((event) => event.id != id)
        .toList();
  }

  void _emitMoment({
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final event = GameMomentEvent(
      id: ++_momentIdCounter,
      title: title,
      subtitle: subtitle,
      color: color,
    );
    final trimmed = <GameMomentEvent>[...gameMomentEvents.value, event];
    gameMomentEvents.value = trimmed.takeLast(3).toList();
  }

  void removeGameMoment(int id) {
    gameMomentEvents.value = gameMomentEvents.value
        .where((event) => event.id != id)
        .toList();
  }

  Future<void> handleAppLifecycleChange(
    AppLifecycleState appLifecycleState,
  ) async {
    if (!_ready) {
      return;
    }

    if (appLifecycleState == AppLifecycleState.paused ||
        appLifecycleState == AppLifecycleState.inactive ||
        appLifecycleState == AppLifecycleState.detached) {
      await saveNow();
      _stopRuntimeLoops();
      return;
    }

    if (appLifecycleState == AppLifecycleState.resumed) {
      _lastTickTime = DateTime.now();
      _tryCreateOfflineEarnings();
      _startRuntimeLoops();
      notifyListeners();
    }
  }

  bool performPrestigeReset() {
    if (!canPrestige) {
      return false;
    }

    final gainedChips = estimatedPrestigeGain;
    if (gainedChips <= 0) {
      return false;
    }

    _state.goldenChips += gainedChips;
    _state.prestigeCount += 1;
    _state.coins = 0;
    _state.lifetimeCoinsSincePrestige = 0;
    _state.globalUpgrades = GlobalUpgrades.initial();
    _state.boost2xEndEpochMs = 0;
    _state.majorActionCount = 0;

    for (final station in _stations) {
      station.resetForPrestige(unlockedAfterReset: station.definition.id == 0);
    }

    _collectCombo = 0;
    _emitMoment(
      title: 'Prestige Complete',
      subtitle: '+$gainedChips Golden Chips',
      color: controllerColorGold,
    );
    unawaited(_hapticsService.heavy(enabled: _state.hapticsEnabled));
    notifyListeners();
    unawaited(saveNow());
    return true;
  }

  Future<void> saveNow() async {
    if (!_ready) {
      return;
    }

    _refreshBestIncomePerSecond();
    _state.lastSavedEpochMs = DateTime.now().millisecondsSinceEpoch;
    await _storageService.saveGameState(_state);
  }

  @override
  void dispose() {
    _stopRuntimeLoops();
    coinParticleEvents.dispose();
    gameMomentEvents.dispose();
    super.dispose();
  }
}

const controllerColorSky = Color(0xFF0284C7);
const controllerColorMint = Color(0xFF059669);
const controllerColorViolet = Color(0xFF7C3AED);
const controllerColorGold = Color(0xFFD97706);

extension _TakeLastExt<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) {
      return this;
    }
    return sublist(length - count);
  }
}
