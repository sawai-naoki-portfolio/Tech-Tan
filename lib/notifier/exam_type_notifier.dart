import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/exam_type.dart';

/// ---------------------------------------------------------------------------
/// ExamTypeNotifier
/// ─ 「いま勉強している試験」を保持する。実践問題・単語テスト・ニュースなど
///   アプリ全体の既定の出題範囲になるため、アプリを閉じても保持する。
/// ---------------------------------------------------------------------------
class ExamTypeNotifier extends Notifier<ExamType> {
  static const _storageKey = 'selected_exam';

  @override
  ExamType build() {
    // 保存値の読み込みは非同期のため、まずは既定値を返してから差し替える
    _load();
    return ExamType.itPassport;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = ExamType.fromId(prefs.getString(_storageKey));
  }

  Future<void> select(ExamType exam) async {
    if (state == exam) return;
    state = exam;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, exam.id);
  }
}
