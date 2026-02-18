import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../models/upgrades.dart';
import '../widgets/coin_particle_overlay.dart';
import '../widgets/game_moment_overlay.dart';
import '../widgets/hud.dart';
import '../widgets/modal_offline_earnings.dart';
import 'empire_screen.dart';
import 'prestige_screen.dart';
import 'shop_screen.dart';
import 'skins_screen.dart';
import 'upgrades_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentTabIndex = 0;
  bool _offlineDialogOpen = false;
  int _lastOfflineDialogEpochMs = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<GameController>().handleAppLifecycleChange(state);
  }

  void _handleOfflineModalIfNeeded(
    BuildContext context,
    GameController controller,
  ) {
    final pending = controller.pendingOfflineEarnings;
    if (pending == null || _offlineDialogOpen) {
      return;
    }

    if (_lastOfflineDialogEpochMs == pending.computedAtEpochMs) {
      return;
    }

    _offlineDialogOpen = true;
    _lastOfflineDialogEpochMs = pending.computedAtEpochMs;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return OfflineEarningsModal(
            awayDuration: pending.awayDuration,
            baseCoins: pending.baseCoins,
            onCollect: () {
              controller.collectOfflineEarnings(doubled: false);
              Navigator.of(dialogContext).pop();
            },
            onCollectDouble: () async {
              await controller.collectOfflineEarningsWithRewardedDouble();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
          );
        },
      ).whenComplete(() {
        _offlineDialogOpen = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        _handleOfflineModalIfNeeded(context, controller);

        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: _ParallaxBackground(theme: controller.selectedTheme),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Hud(
                      controller: controller,
                      onAvatarTapped: () {
                        setState(() {
                          _currentTabIndex = 3;
                        });
                      },
                      onPrestigeTapped: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PrestigeScreen(),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _currentTabIndex,
                        children: [
                          EmpireScreen(
                            onPrestigePressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PrestigeScreen(),
                                ),
                              );
                            },
                          ),
                          const UpgradesScreen(),
                          const ShopScreen(),
                          const SkinsScreen(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: CoinParticleOverlay(controller: controller),
              ),
              Positioned.fill(child: GameMomentOverlay(controller: controller)),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: const Color(0xFF0B1120).withValues(alpha: 0.9),
                selectedItemColor: controller.selectedTheme.stationAccent,
                unselectedItemColor: const Color(0xFF93A3B8),
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
                currentIndex: _currentTabIndex,
                onTap: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.auto_awesome_mosaic),
                    label: 'Empire',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.upgrade),
                    label: 'Upgrades',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.storefront),
                    label: 'Shop',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.palette),
                    label: 'Skins',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParallaxBackground extends StatefulWidget {
  const _ParallaxBackground({required this.theme});

  final ThemePalette theme;

  @override
  State<_ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<_ParallaxBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.theme.gradient,
                ),
              ),
            ),
            const _SoftGridOverlay(),
            Positioned(
              top: 110 + sin(t * pi * 2) * 16,
              right: 26,
              child: _floatingSnack('🍔', 30, 0.18),
            ),
            Positioned(
              top: 190 + cos(t * pi * 2) * 14,
              left: 24,
              child: _floatingSnack('🍩', 24, 0.16),
            ),
            Positioned(
              top: 318 + sin(t * pi * 2) * 22,
              right: 48,
              child: _floatingSnack('🍿', 26, 0.15),
            ),
            Positioned(
              top: 80 + sin(t * pi * 2) * 20,
              left: -40,
              child: _blurBubble(
                size: 180,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            Positioned(
              top: 280 + cos(t * pi * 2) * 28,
              right: -30,
              child: _blurBubble(
                size: 150,
                color: widget.theme.stationAccent.withValues(alpha: 0.22),
              ),
            ),
            Positioned(
              bottom: -40 + sin(t * pi * 2) * 26,
              left: 90,
              child: _blurBubble(
                size: 200,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 210,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _blurBubble({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _floatingSnack(String emoji, double size, double alpha) {
    return Opacity(
      opacity: alpha,
      child: Transform.rotate(
        angle: size / 100,
        child: Text(
          emoji,
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _SoftGridOverlay extends StatelessWidget {
  const _SoftGridOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _GridPainter()));
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const gap = 36.0;
    for (var x = 0.0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
