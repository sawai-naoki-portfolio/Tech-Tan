import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------------------------
/// MistakeCountNotifier
/// ─ 単語テストでの誤答回数を「単語名 → 回数」で累計する。
/// ---------------------------------------------------------------------------
class MistakeCountNotifier extends Notifier<Map<String, int>> {
  static const _storageKey = 'mistake_counts';

  @override
  Map<String, int> build() {
    _loadCounts();
    return const {};
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      state = Map<String, int>.from(jsonDecode(data) as Map);
    }
  }

  Future<void> increment(String wordName) async {
    state = {...state, wordName: (state[wordName] ?? 0) + 1};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state));
  }
}
