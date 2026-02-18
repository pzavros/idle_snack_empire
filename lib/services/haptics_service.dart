import 'package:flutter/services.dart';

class HapticsService {
  const HapticsService();

  Future<void> light({required bool enabled}) async {
    if (!enabled) {
      return;
    }
    await HapticFeedback.lightImpact();
  }

  Future<void> medium({required bool enabled}) async {
    if (!enabled) {
      return;
    }
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavy({required bool enabled}) async {
    if (!enabled) {
      return;
    }
    await HapticFeedback.heavyImpact();
  }
}
