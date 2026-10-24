import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------------------------
/// CheckedQuestionsNotifier
/// ─ 「単語チェック問題」に登録した単語名の集合を管理する。
/// ---------------------------------------------------------------------------
class CheckedQuestionsNotifier extends Notifier<Set<String>> {
  static const _storageKey = 'checked_questions';

  @override
  Set<String> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.union((prefs.getStringList(_storageKey) ?? []).toSet());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state.toList());
  }

  Future<void> add(String wordName) async {
    if (state.contains(wordName)) return;
    state = {...state, wordName};
    await _save();
  }

  Future<void> remove(String wordName) async {
    if (!state.contains(wordName)) return;
    state = state.where((name) => name != wordName).toSet();
    await _save();
  }

  Future<void> toggle(String wordName) async {
    if (state.contains(wordName)) {
      await remove(wordName);
    } else {
      await add(wordName);
    }
  }
}
