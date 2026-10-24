import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------------------------
/// QuestionMistakeNotifier
/// ─ 実践問題（過去問）ごとの誤答回数を「問題 ID → 回数」で管理する。
///   苦手復習モードの出題順は、この記録を元に決まる。
/// ---------------------------------------------------------------------------
class QuestionMistakeNotifier extends Notifier<Map<String, int>> {
  static const _storageKey = 'question_mistake_counts';

  @override
  Map<String, int> build() {
    // 保存値の読み込みは非同期のため、まずは空で返してから差し替える
    _load();
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      state = Map<String, int>.from(jsonDecode(data) as Map);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state));
  }

  /// 誤答したときに 1 増やす
  Future<void> increment(String questionId) async {
    state = {...state, questionId: (state[questionId] ?? 0) + 1};
    await _save();
  }

  /// 克服できた問題を苦手リストから外す
  Future<void> clear(String questionId) async {
    if (!state.containsKey(questionId)) return;
    state = {...state}..remove(questionId);
    await _save();
  }
}
