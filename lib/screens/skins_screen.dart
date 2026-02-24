import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../models/upgrades.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/number_format.dart';

class SkinsScreen extends StatelessWidget {
  const SkinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
          children: [
            const ArcadePanel(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              tint: Color(0xFF3F1D4D),
              child: Text(
                'STYLE LAB  Customize your empire vibe',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Themes',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final theme in kThemePalettes)
                    _ThemeTile(
                      theme: theme,
                      isUnlocked: controller.isThemeUnlocked(theme.id),
                      isSelected: controller.state.selectedTheme == theme.id,
                      canAfford: controller.coins >= theme.unlockCost,
                      onTap: () {
                        if (!controller.isThemeUnlocked(theme.id)) {
                          final unlocked = controller.unlockTheme(theme);
                          if (!unlocked) {
                            return;
                          }
                        }
                        controller.selectTheme(theme.id);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Avatars',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final avatar in kAvatarOptions)
                    _AvatarTile(
                      avatar: avatar,
                      isUnlocked: controller.isAvatarUnlocked(avatar.id),
                      isSelected: controller.state.selectedAvatar == avatar.id,
                      canAfford: controller.coins >= avatar.unlockCost,
                      onTap: () {
                        if (!controller.isAvatarUnlocked(avatar.id)) {
                          final unlocked = controller.unlockAvatar(avatar);
                          if (!unlocked) {
                            return;
                          }
                        }
                        controller.selectAvatar(avatar.id);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Settings',
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sound'),
                    value: controller.state.soundEnabled,
                    onChanged: controller.setSoundEnabled,
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Haptics'),
                    value: controller.state.hapticsEnabled,
                    onChanged: controller.setHapticsEnabled,
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

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
              fontWeight: FontWeight.w900,
              fontSize: 18,
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

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.theme,
    required this.isUnlocked,
    required this.isSelected,
    required this.canAfford,
    required this.onTap,
  });

  final ThemePalette theme;
  final bool isUnlocked;
  final bool isSelected;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 106,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: (isUnlocked || canAfford) ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? theme.stationAccent
                  : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(colors: theme.gradient),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                theme.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isUnlocked
                    ? (isSelected ? 'Selected' : 'Tap to use')
                    : formatCoins(theme.unlockCost),
                style: TextStyle(
                  fontSize: 11,
                  color: isUnlocked
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFFB45309),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.avatar,
    required this.isUnlocked,
    required this.isSelected,
    required this.canAfford,
    required this.onTap,
  });

  final AvatarOption avatar;
  final bool isUnlocked;
  final bool isSelected;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 106,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: (isUnlocked || canAfford) ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? avatar.color
                  : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatar.color.withValues(alpha: 0.2),
                ),
                child: Icon(avatar.icon, color: avatar.color),
              ),
              const SizedBox(height: 6),
              Text(
                avatar.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isUnlocked
                    ? (isSelected ? 'Selected' : 'Tap to use')
                    : formatCoins(avatar.unlockCost),
                style: TextStyle(
                  fontSize: 11,
                  color: isUnlocked
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFFB45309),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
