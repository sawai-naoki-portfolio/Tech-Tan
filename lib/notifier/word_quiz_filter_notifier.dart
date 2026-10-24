import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/exam_type.dart';
import '../utility/word.dart';

/// ---------------------------------------------------------------------------
/// WordQuizFilterNotifier
/// ─ 単語テストの出題範囲（どの試験の単語から出すか）を管理する。
///   状態は Word.category の集合。
/// ---------------------------------------------------------------------------
class WordQuizFilterNotifier extends Notifier<Set<String>> {
  static const _storageKey = 'word_quiz_filters';

  @override
  Set<String> build() {
    // 保存値の読み込みは非同期のため、まずは既定値を返してから差し替える
    _load();
    return defaultFilters;
  }

  /// 選択可能な出題範囲（画面の表示順もこの順に従う）
  static final availableFilters = <String>[
    ...ExamType.values.map((e) => e.label),
    Word.customCategory,
  ];

  /// 初期状態は全範囲を有効にする。
  /// 自分で追加した単語も既定で出題対象に含める（説明が空のものは出題側で除外される）。
  static final defaultFilters = availableFilters.toSet();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    final list = jsonDecode(raw) as List<dynamic>;
    state = list.map((e) => e.toString()).toSet();
  }

  Future<void> updateFilters(Set<String> newFilters) async {
    state = newFilters;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toList()));
  }

  Future<void> toggleFilter(String key, bool isSelected) async {
    final newFilters = {...state};
    if (isSelected) {
      newFilters.add(key);
    } else {
      newFilters.remove(key);
    }
    await updateFilters(newFilters);
  }
}
