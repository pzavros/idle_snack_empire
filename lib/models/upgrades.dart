import 'package:flutter/material.dart';

class GlobalUpgrades {
  GlobalUpgrades({required this.profitTier, required this.speedTier});

  factory GlobalUpgrades.initial() {
    return GlobalUpgrades(profitTier: 0, speedTier: 0);
  }

  factory GlobalUpgrades.fromJson(Map<String, dynamic> json) {
    return GlobalUpgrades(
      profitTier: (json['profitTier'] as num?)?.toInt() ?? 0,
      speedTier: (json['speedTier'] as num?)?.toInt() ?? 0,
    );
  }

  int profitTier;
  int speedTier;

  Map<String, dynamic> toJson() {
    return {'profitTier': profitTier, 'speedTier': speedTier};
  }
}

class ThemePalette {
  const ThemePalette({
    required this.id,
    required this.name,
    required this.unlockCost,
    required this.gradient,
    required this.stationAccent,
  });

  final int id;
  final String name;
  final double unlockCost;
  final List<Color> gradient;
  final Color stationAccent;
}

const List<ThemePalette> kThemePalettes = [
  ThemePalette(
    id: 0,
    name: 'Classic',
    unlockCost: 0,
    gradient: [Color(0xFFFFF1CC), Color(0xFFF8C380), Color(0xFFEFA65D)],
    stationAccent: Color(0xFFFFA000),
  ),
  ThemePalette(
    id: 1,
    name: 'Neon',
    unlockCost: 600,
    gradient: [Color(0xFF051937), Color(0xFF004D7A), Color(0xFF00C9A7)],
    stationAccent: Color(0xFF00F5FF),
  ),
  ThemePalette(
    id: 2,
    name: 'Candy',
    unlockCost: 1800,
    gradient: [Color(0xFFFFE3EC), Color(0xFFFFB9D7), Color(0xFFFF8AB5)],
    stationAccent: Color(0xFFFF4E9B),
  ),
  ThemePalette(
    id: 3,
    name: 'Night',
    unlockCost: 5500,
    gradient: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
    stationAccent: Color(0xFF60A5FA),
  ),
  ThemePalette(
    id: 4,
    name: 'Ocean',
    unlockCost: 18000,
    gradient: [Color(0xFF003566), Color(0xFF0077B6), Color(0xFF48CAE4)],
    stationAccent: Color(0xFF90E0EF),
  ),
  ThemePalette(
    id: 5,
    name: 'Sunset',
    unlockCost: 45000,
    gradient: [Color(0xFF3A0CA3), Color(0xFFF72585), Color(0xFFFF9E00)],
    stationAccent: Color(0xFFFFD166),
  ),
];

class AvatarOption {
  const AvatarOption({
    required this.id,
    required this.name,
    required this.unlockCost,
    required this.icon,
    required this.color,
  });

  final int id;
  final String name;
  final double unlockCost;
  final IconData icon;
  final Color color;
}

const List<AvatarOption> kAvatarOptions = [
  AvatarOption(
    id: 0,
    name: 'Chef',
    unlockCost: 0,
    icon: Icons.restaurant,
    color: Color(0xFFE67E22),
  ),
  AvatarOption(
    id: 1,
    name: 'Popper',
    unlockCost: 350,
    icon: Icons.local_fire_department,
    color: Color(0xFFF94144),
  ),
  AvatarOption(
    id: 2,
    name: 'Doughy',
    unlockCost: 1200,
    icon: Icons.donut_small,
    color: Color(0xFFF3722C),
  ),
  AvatarOption(
    id: 3,
    name: 'Griller',
    unlockCost: 2800,
    icon: Icons.outdoor_grill,
    color: Color(0xFF90BE6D),
  ),
  AvatarOption(
    id: 4,
    name: 'Pizzaiolo',
    unlockCost: 7000,
    icon: Icons.local_pizza,
    color: Color(0xFFF9C74F),
  ),
  AvatarOption(
    id: 5,
    name: 'Sushi Pro',
    unlockCost: 18000,
    icon: Icons.set_meal,
    color: Color(0xFF43AA8B),
  ),
  AvatarOption(
    id: 6,
    name: 'Scooper',
    unlockCost: 50000,
    icon: Icons.icecream,
    color: Color(0xFF577590),
  ),
  AvatarOption(
    id: 7,
    name: 'Tycoon',
    unlockCost: 150000,
    icon: Icons.factory,
    color: Color(0xFFB5179E),
  ),
];
