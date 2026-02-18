# Idle Snack Empire

Offline idle/incremental mobile game built with Flutter.

## Features

- 14 snack stations across 7 progression stages.
- Harder unlock pacing: station unlocks require both coins and previous station level milestones.
- Tougher economy scaling for level costs and global upgrade tiers.
- Global upgrades for all-profit and all-speed multipliers.
- Tick-based idle loop with smooth station progress bars.
- Offline earnings (clamped to 12 hours) with collect and rewarded-2x flow.
- Shop boosts:
  - 2x income for 15 minutes
  - instant 5-minute income pack
  - remove-ads placeholder
- Cosmetics:
  - 6 unlockable themes
  - 8 unlockable avatars
- Prestige system with Golden Chips and permanent multiplier.
- Haptics hooks (light/medium/heavy), optional sound toggle (no-op), ad hooks via stub service.
- Full local persistence with `SharedPreferences`.

## Run

1. Install Flutter stable.
2. From project root:

```bash
flutter pub get
flutter run
```

Use a connected iOS simulator or Android emulator/device.

## Project Structure

```
lib/
  main.dart
  app.dart
  models/
    game_state.dart
    station.dart
    upgrades.dart
  controllers/
    game_controller.dart
    economy.dart
    offline_earnings.dart
  services/
    storage_service.dart
    ads_service.dart
    haptics_service.dart
  screens/
    home_screen.dart
    empire_screen.dart
    upgrades_screen.dart
    shop_screen.dart
    skins_screen.dart
    prestige_screen.dart
  widgets/
    arcade_panel.dart
    hud.dart
    station_card.dart
    animated_coin_counter.dart
    coin_particle_overlay.dart
    game_moment_overlay.dart
    purchase_button.dart
    modal_offline_earnings.dart
```

## Ads Integration (AdMob Later)

Current ad integration point is `lib/services/ads_service.dart`.

- `AdsService` defines:
  - `Future<bool> showRewarded()`
  - `Future<void> showInterstitial()`
- `StubAdsService` is currently used and simulates success.

To plug AdMob later:

1. Add `google_mobile_ads`.
2. Create a real `AdsService` implementation that loads/shows rewarded/interstitial ads.
3. Replace `StubAdsService` provider in `lib/app.dart` with your AdMob service.

## Save Data Storage

- Persistence service: `lib/services/storage_service.dart`
- Storage backend: `SharedPreferences`
- Save key: `idle_snack_empire_save_v1`
- Stored data includes:
  - coins, lifetime coins, golden chips
  - selected/unlocked themes and avatars
  - station states (levels, unlocks, automation, multipliers, progress, queued cycles)
  - boost timers
  - best stats and last save time
  - settings (sound/haptics)

Autosave triggers:

- Every 10 seconds
- App lifecycle changes (pause/inactive/detach)

Offline earnings are computed on startup/resume using elapsed wall time since last save.
