import 'package:flutter/foundation.dart';

class StationDefinition {
  const StationDefinition({
    required this.id,
    required this.name,
    required this.unlockCost,
    required this.baseCost,
    required this.baseProfit,
    required this.baseCycleSeconds,
    required this.managerCost,
    required this.profitUpgradeCost,
    required this.icon,
  });

  final int id;
  final String name;
  final double unlockCost;
  final double baseCost;
  final double baseProfit;
  final double baseCycleSeconds;
  final double managerCost;
  final double profitUpgradeCost;
  final String icon;
}

const List<StationDefinition> kStationDefinitions = [
  StationDefinition(
    id: 0,
    name: 'Lemonade Stand',
    unlockCost: 0,
    baseCost: 20,
    baseProfit: 4.5,
    baseCycleSeconds: 2.2,
    managerCost: 220,
    profitUpgradeCost: 360,
    icon: '🍋',
  ),
  StationDefinition(
    id: 1,
    name: 'Popcorn Cart',
    unlockCost: 320,
    baseCost: 180,
    baseProfit: 12,
    baseCycleSeconds: 3.2,
    managerCost: 900,
    profitUpgradeCost: 1400,
    icon: '🍿',
  ),
  StationDefinition(
    id: 2,
    name: 'Donut Fryer',
    unlockCost: 2400,
    baseCost: 980,
    baseProfit: 42,
    baseCycleSeconds: 4.2,
    managerCost: 4500,
    profitUpgradeCost: 6800,
    icon: '🍩',
  ),
  StationDefinition(
    id: 3,
    name: 'Burger Grill',
    unlockCost: 14000,
    baseCost: 5200,
    baseProfit: 160,
    baseCycleSeconds: 5.4,
    managerCost: 22000,
    profitUpgradeCost: 30000,
    icon: '🍔',
  ),
  StationDefinition(
    id: 4,
    name: 'Pizza Oven',
    unlockCost: 68000,
    baseCost: 25000,
    baseProfit: 560,
    baseCycleSeconds: 6.4,
    managerCost: 110000,
    profitUpgradeCost: 150000,
    icon: '🍕',
  ),
  StationDefinition(
    id: 5,
    name: 'Sushi Counter',
    unlockCost: 320000,
    baseCost: 105000,
    baseProfit: 1900,
    baseCycleSeconds: 7.3,
    managerCost: 480000,
    profitUpgradeCost: 680000,
    icon: '🍣',
  ),
  StationDefinition(
    id: 6,
    name: 'Ice Cream Lab',
    unlockCost: 1500000,
    baseCost: 430000,
    baseProfit: 6500,
    baseCycleSeconds: 8.3,
    managerCost: 2200000,
    profitUpgradeCost: 3000000,
    icon: '🍨',
  ),
  StationDefinition(
    id: 7,
    name: 'Mega Snack Factory',
    unlockCost: 7000000,
    baseCost: 1900000,
    baseProfit: 22000,
    baseCycleSeconds: 9.8,
    managerCost: 9800000,
    profitUpgradeCost: 13000000,
    icon: '🏭',
  ),
  StationDefinition(
    id: 8,
    name: 'Taco Truck',
    unlockCost: 30000000,
    baseCost: 7600000,
    baseProfit: 76000,
    baseCycleSeconds: 10.8,
    managerCost: 42000000,
    profitUpgradeCost: 56000000,
    icon: '🌮',
  ),
  StationDefinition(
    id: 9,
    name: 'Noodle Bar',
    unlockCost: 120000000,
    baseCost: 29000000,
    baseProfit: 240000,
    baseCycleSeconds: 11.6,
    managerCost: 170000000,
    profitUpgradeCost: 230000000,
    icon: '🍜',
  ),
  StationDefinition(
    id: 10,
    name: 'Chocolate Forge',
    unlockCost: 480000000,
    baseCost: 110000000,
    baseProfit: 820000,
    baseCycleSeconds: 12.4,
    managerCost: 650000000,
    profitUpgradeCost: 900000000,
    icon: '🍫',
  ),
  StationDefinition(
    id: 11,
    name: 'Royal Buffet',
    unlockCost: 1900000000,
    baseCost: 410000000,
    baseProfit: 2700000,
    baseCycleSeconds: 13.4,
    managerCost: 2500000000,
    profitUpgradeCost: 3400000000,
    icon: '🍽️',
  ),
  StationDefinition(
    id: 12,
    name: 'Sky Diner',
    unlockCost: 7600000000,
    baseCost: 1500000000,
    baseProfit: 8600000,
    baseCycleSeconds: 14,
    managerCost: 9800000000,
    profitUpgradeCost: 13000000000,
    icon: '🛸',
  ),
  StationDefinition(
    id: 13,
    name: 'Orbital Snack Port',
    unlockCost: 30000000000,
    baseCost: 5600000000,
    baseProfit: 28000000,
    baseCycleSeconds: 15,
    managerCost: 38000000000,
    profitUpgradeCost: 51000000000,
    icon: '🌌',
  ),
];

class StationData {
  StationData({
    required this.id,
    required this.level,
    required this.speedMultiplier,
    required this.profitMultiplier,
    required this.isUnlocked,
    required this.isAutomated,
    required this.hasProfitUpgrade,
    required this.progress,
    required this.pendingCollections,
    required this.lastTickEpochMs,
  });

  factory StationData.initial({required int id, required bool unlocked}) {
    return StationData(
      id: id,
      level: unlocked ? 1 : 0,
      speedMultiplier: 1,
      profitMultiplier: 1,
      isUnlocked: unlocked,
      isAutomated: false,
      hasProfitUpgrade: false,
      progress: 0,
      pendingCollections: 0,
      lastTickEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory StationData.fromJson(Map<String, dynamic> json) {
    return StationData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 0,
      speedMultiplier: (json['speedMultiplier'] as num?)?.toDouble() ?? 1,
      profitMultiplier: (json['profitMultiplier'] as num?)?.toDouble() ?? 1,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isAutomated: json['isAutomated'] as bool? ?? false,
      hasProfitUpgrade: json['hasProfitUpgrade'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      pendingCollections: (json['pendingCollections'] as num?)?.toInt() ?? 0,
      lastTickEpochMs: (json['lastTickEpochMs'] as num?)?.toInt() ?? 0,
    );
  }

  final int id;
  int level;
  double speedMultiplier;
  double profitMultiplier;
  bool isUnlocked;
  bool isAutomated;
  bool hasProfitUpgrade;
  double progress;
  int pendingCollections;
  int lastTickEpochMs;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'speedMultiplier': speedMultiplier,
      'profitMultiplier': profitMultiplier,
      'isUnlocked': isUnlocked,
      'isAutomated': isAutomated,
      'hasProfitUpgrade': hasProfitUpgrade,
      'progress': progress,
      'pendingCollections': pendingCollections,
      'lastTickEpochMs': lastTickEpochMs,
    };
  }
}

class Station extends ChangeNotifier {
  Station({required this.definition, required this.data});

  final StationDefinition definition;
  final StationData data;

  int get level => data.level;
  bool get isUnlocked => data.isUnlocked;
  bool get isAutomated => data.isAutomated;
  bool get hasProfitUpgrade => data.hasProfitUpgrade;
  double get progress => data.progress;
  int get pendingCollections => data.pendingCollections;

  double effectiveCycleSeconds(double globalSpeedMultiplier) {
    final speed = data.speedMultiplier * globalSpeedMultiplier;
    return definition.baseCycleSeconds / speed.clamp(0.1, 1000);
  }

  double baseProfitPerCycle() {
    if (!data.isUnlocked || data.level <= 0) {
      return 0;
    }
    return definition.baseProfit * data.level * data.profitMultiplier;
  }

  int advance({
    required double elapsedSeconds,
    required double globalSpeedMultiplier,
    required int nowEpochMs,
  }) {
    if (!data.isUnlocked || data.level <= 0) {
      return 0;
    }

    final cycle = effectiveCycleSeconds(globalSpeedMultiplier);
    if (cycle <= 0) {
      return 0;
    }

    data.lastTickEpochMs = nowEpochMs;
    data.progress += elapsedSeconds / cycle;
    var completedCycles = 0;
    if (data.progress >= 1) {
      completedCycles = data.progress.floor();
      data.progress -= completedCycles;
      if (!data.isAutomated) {
        data.pendingCollections += completedCycles;
      }
    }

    notifyListeners();
    return data.isAutomated ? completedCycles : 0;
  }

  int collectPendingCycles() {
    final queued = data.pendingCollections;
    if (queued <= 0) {
      return 0;
    }
    data.pendingCollections = 0;
    notifyListeners();
    return queued;
  }

  void unlock() {
    data.isUnlocked = true;
    if (data.level == 0) {
      data.level = 1;
    }
    notifyListeners();
  }

  void levelUp() {
    data.level += 1;
    notifyListeners();
  }

  void enableAutomation() {
    data.isAutomated = true;
    notifyListeners();
  }

  void applyProfitUpgrade() {
    if (data.hasProfitUpgrade) {
      return;
    }
    data.hasProfitUpgrade = true;
    data.profitMultiplier *= 2;
    notifyListeners();
  }

  void resetForPrestige({required bool unlockedAfterReset}) {
    data.level = unlockedAfterReset ? 1 : 0;
    data.speedMultiplier = 1;
    data.profitMultiplier = 1;
    data.isUnlocked = unlockedAfterReset;
    data.isAutomated = false;
    data.hasProfitUpgrade = false;
    data.progress = 0;
    data.pendingCollections = 0;
    data.lastTickEpochMs = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }
}
