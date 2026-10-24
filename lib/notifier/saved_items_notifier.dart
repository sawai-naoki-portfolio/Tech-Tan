import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------------------------
/// SavedItemsNotifier
/// ─ ユーザーが保存した単語の名前を、保存順のまま管理する。
/// ---------------------------------------------------------------------------
class SavedItemsNotifier extends Notifier<List<String>> {
  static const _storageKey = 'saved_items';

  @override
  List<String> build() {
    _loadSavedItems();
    return const [];
  }

  Future<void> _loadSavedItems() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_storageKey) ?? const [];
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, state);
  }

  Future<void> saveItem(String wordName) async {
    if (state.contains(wordName)) return;
    state = [...state, wordName];
    await _save();
  }

  Future<void> removeItem(String wordName) async {
    if (!state.contains(wordName)) return;
    state = state.where((e) => e != wordName).toList();
    await _save();
  }

  Future<void> reorderItems(List<String> newOrder) async {
    state = newOrder;
    await _save();
  }
}
