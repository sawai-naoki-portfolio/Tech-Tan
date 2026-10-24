import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------------------------
/// SearchHistoryNotifier
/// ─ 検索して開いた単語を、新しい順に最大 15 件まで保持する。
/// ---------------------------------------------------------------------------
class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _storageKey = 'search_history';
  static const _maxEntries = 15;

  @override
  List<String> build() {
    _loadHistory();
    return const [];
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_storageKey) ?? const [];
  }

  Future<void> addWord(String wordName) async {
    final newHistory = List<String>.from(state)
      ..remove(wordName) // 重複があれば削除
      ..insert(0, wordName); // 最新を先頭に追加
    state = newHistory.take(_maxEntries).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state);
  }

  Future<void> clearHistory() async {
    state = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, const []);
  }
}
