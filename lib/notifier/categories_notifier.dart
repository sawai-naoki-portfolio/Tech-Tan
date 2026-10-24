import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/category.dart';

/// ---------------------------------------------------------------------------
/// CategoriesNotifier
/// ─ リストの作成、更新、削除および単語の所属更新、並び替えを管理する
/// ---------------------------------------------------------------------------
class CategoriesNotifier extends Notifier<List<Category>> {
  static const _storageKey = 'saved_categories';

  @override
  List<Category> build() {
    // 保存値の読み込みは非同期のため、まずは空で返してから差し替える
    _loadCategories();
    return const [];
  }

  Future<void> reorderWords(
      String categoryName, int oldIndex, int newIndex) async {
    state = state.map((c) {
      if (c.name == categoryName) {
        final newWords = List<String>.from(c.words);
        final item = newWords.removeAt(oldIndex);
        newWords.insert(newIndex, item);
        return Category(name: c.name, words: newWords);
      }
      return c;
    }).toList();
    await _saveCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      state = decoded
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(state.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  Future<void> addCategory(String name) async {
    if (state.any((c) => c.name == name)) return;
    state = [...state, Category(name: name)];
    await _saveCategories();
  }

  Future<void> updateCategory(String oldName, String newName) async {
    state = state.map((c) {
      if (c.name == oldName) {
        return Category(name: newName, words: c.words);
      }
      return c;
    }).toList();
    await _saveCategories();
  }

  Future<void> deleteCategory(String name) async {
    state = state.where((c) => c.name != name).toList();
    await _saveCategories();
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final updated = List<Category>.from(state);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = updated;
    await _saveCategories();
  }

  Future<void> updateWordAssignment(
      String categoryName, String wordName, bool assigned) async {
    state = state.map((c) {
      if (c.name == categoryName) {
        final updatedWords = List<String>.from(c.words);
        if (assigned) {
          if (!updatedWords.contains(wordName)) updatedWords.add(wordName);
        } else {
          updatedWords.remove(wordName);
        }
        return Category(name: c.name, words: updatedWords);
      }
      return c;
    }).toList();
    await _saveCategories();
  }
}
