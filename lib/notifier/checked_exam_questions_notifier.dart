import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------------------------
/// CheckedExamQuestionsNotifier
/// ─ 「あとで解き直す」ものとして登録した実践問題の ID を管理する。
///   単語側の CheckedQuestionsNotifier と同じ役割を、過去問に対して果たす。
/// ---------------------------------------------------------------------------
class CheckedExamQuestionsNotifier extends Notifier<Set<String>> {
  static const _storageKey = 'checked_exam_questions';

  @override
  Set<String> build() {
    // 保存値の読み込みは非同期のため、まずは空で返してから差し替える
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

  Future<void> add(String questionId) async {
    if (state.contains(questionId)) return;
    state = {...state, questionId};
    await _save();
  }

  Future<void> remove(String questionId) async {
    if (!state.contains(questionId)) return;
    state = state.where((id) => id != questionId).toSet();
    await _save();
  }

  Future<void> toggle(String questionId) async {
    if (state.contains(questionId)) {
      await remove(questionId);
    } else {
      await add(questionId);
    }
  }
}
