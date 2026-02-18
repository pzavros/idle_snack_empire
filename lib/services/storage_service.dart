import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';

class StorageService {
  static const _saveKey = 'idle_snack_empire_save_v1';

  Future<GameState> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null || raw.isEmpty) {
      return GameState.initial();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return GameState.initial();
      }
      return GameState.fromJson(decoded);
    } catch (_) {
      return GameState.initial();
    }
  }

  Future<void> saveGameState(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.toJson());
    await prefs.setString(_saveKey, encoded);
  }
}
