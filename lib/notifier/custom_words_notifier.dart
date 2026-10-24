import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/word.dart';

/// ---------------------------------------------------------------------------
/// CustomWordsNotifier
/// ---------------------------------------------------------------------------
/// ユーザーがアプリ上で追加したカスタム単語のリストを管理する Notifier。
/// 生成時に SharedPreferences からデータをロードし、
/// addWord() / removeWord() で更新すると同時にストレージへ保存します。
class CustomWordsNotifier extends Notifier<List<Word>> {
  static const _storageKey = 'custom_words';

  @override
  List<Word> build() {
    // 保存値の読み込みは非同期のため、まずは空で返してから差し替える
    _loadCustomWords();
    return const [];
  }

  Future<void> _loadCustomWords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey);
    if (jsonList == null) return;

    final words = <Word>[];
    for (final jsonStr in jsonList) {
      try {
        words.add(Word.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>));
      } catch (error) {
        // 壊れたレコードは読み飛ばす（1件の破損で全件が消えるのを防ぐ）
        debugPrint('カスタム単語の復元に失敗しました: $error');
      }
    }
    state = words;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((w) => jsonEncode(w.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  Future<void> addWord(Word word) async {
    state = [...state, word];
    await _save();
  }

  Future<void> removeWord(String name) async {
    state = state.where((w) => w.name != name).toList();
    await _save();
  }
}
