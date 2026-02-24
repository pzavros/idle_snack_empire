import 'station.dart';
import 'upgrades.dart';

class GameState {
  GameState({
    required this.coins,
    required this.lifetimeCoins,
    required this.lifetimeCoinsSincePrestige,
    required this.prestigeCount,
    required this.selectedTheme,
    required this.selectedAvatar,
    required this.unlockedThemes,
    required this.unlockedAvatars,
    required this.stations,
    required this.globalUpgrades,
    required this.boost2xEndEpochMs,
    required this.highestCoins,
    required this.highestIncomePerSecond,
    required this.lastSavedEpochMs,
    required this.empireLevel,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.majorActionCount,
    required this.shopOpenCount,
  });

  factory GameState.initial() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return GameState(
      coins: 120,
      lifetimeCoins: 120,
      lifetimeCoinsSincePrestige: 120,
      prestigeCount: 0,
      selectedTheme: 0,
      selectedAvatar: 0,
      unlockedThemes: {0},
      unlockedAvatars: {0},
      stations: kStationDefinitions
          .map(
            (definition) => StationData.initial(
              id: definition.id,
              unlocked: definition.id == 0,
            ),
          )
          .toList(),
      globalUpgrades: GlobalUpgrades.initial(),
      boost2xEndEpochMs: 0,
      highestCoins: 120,
      highestIncomePerSecond: 0,
      lastSavedEpochMs: now,
      empireLevel: 0,
      soundEnabled: false,
      hapticsEnabled: true,
      majorActionCount: 0,
      shopOpenCount: 0,
    );
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    final stationJson = (json['stations'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final legacyGoldenChips = (json['goldenChips'] as num?)?.toInt() ?? 0;

    return GameState(
      coins: (json['coins'] as num?)?.toDouble() ?? 0,
      lifetimeCoins: (json['lifetimeCoins'] as num?)?.toDouble() ?? 0,
      lifetimeCoinsSincePrestige:
          (json['lifetimeCoinsSincePrestige'] as num?)?.toDouble() ??
          ((json['lifetimeCoins'] as num?)?.toDouble() ?? 0),
      prestigeCount: (json['prestigeCount'] as num?)?.toInt() ?? 0,
      selectedTheme: (json['selectedTheme'] as num?)?.toInt() ?? 0,
      selectedAvatar: (json['selectedAvatar'] as num?)?.toInt() ?? 0,
      unlockedThemes:
          ((json['unlockedThemes'] as List<dynamic>? ?? const [0]).map(
            (value) => (value as num).toInt(),
          )).toSet(),
      unlockedAvatars:
          ((json['unlockedAvatars'] as List<dynamic>? ?? const [0]).map(
            (value) => (value as num).toInt(),
          )).toSet(),
      stations: stationJson.map(StationData.fromJson).toList(),
      globalUpgrades: GlobalUpgrades.fromJson(
        (json['globalUpgrades'] as Map<String, dynamic>?) ?? const {},
      ),
      boost2xEndEpochMs: (json['boost2xEndEpochMs'] as num?)?.toInt() ?? 0,
      highestCoins: (json['highestCoins'] as num?)?.toDouble() ?? 0,
      highestIncomePerSecond:
          (json['highestIncomePerSecond'] as num?)?.toDouble() ?? 0,
      lastSavedEpochMs: (json['lastSavedEpochMs'] as num?)?.toInt() ?? 0,
      empireLevel: (json['empireLevel'] as num?)?.toInt() ?? legacyGoldenChips,
      soundEnabled: json['soundEnabled'] as bool? ?? false,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      majorActionCount: (json['majorActionCount'] as num?)?.toInt() ?? 0,
      shopOpenCount: (json['shopOpenCount'] as num?)?.toInt() ?? 0,
    );
  }

  double coins;
  double lifetimeCoins;
  double lifetimeCoinsSincePrestige;
  int prestigeCount;
  int selectedTheme;
  int selectedAvatar;
  Set<int> unlockedThemes;
  Set<int> unlockedAvatars;
  List<StationData> stations;
  GlobalUpgrades globalUpgrades;
  int boost2xEndEpochMs;
  double highestCoins;
  double highestIncomePerSecond;
  int lastSavedEpochMs;
  int empireLevel;
  bool soundEnabled;
  bool hapticsEnabled;
  int majorActionCount;
  int shopOpenCount;

  Map<String, dynamic> toJson() {
    return {
      'coins': coins,
      'lifetimeCoins': lifetimeCoins,
      'lifetimeCoinsSincePrestige': lifetimeCoinsSincePrestige,
      'prestigeCount': prestigeCount,
      'selectedTheme': selectedTheme,
      'selectedAvatar': selectedAvatar,
      'unlockedThemes': unlockedThemes.toList(),
      'unlockedAvatars': unlockedAvatars.toList(),
      'stations': stations.map((station) => station.toJson()).toList(),
      'globalUpgrades': globalUpgrades.toJson(),
      'boost2xEndEpochMs': boost2xEndEpochMs,
      'highestCoins': highestCoins,
      'highestIncomePerSecond': highestIncomePerSecond,
      'lastSavedEpochMs': lastSavedEpochMs,
      'empireLevel': empireLevel,
      'goldenChips': empireLevel,
      'soundEnabled': soundEnabled,
      'hapticsEnabled': hapticsEnabled,
      'majorActionCount': majorActionCount,
      'shopOpenCount': shopOpenCount,
    };
  }
}
