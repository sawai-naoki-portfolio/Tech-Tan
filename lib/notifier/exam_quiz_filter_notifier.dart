import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/exam_quiz_filter.dart';
import '../utility/exam_type.dart';

/// ---------------------------------------------------------------------------
/// ExamQuizFilterNotifier
/// ─ 実践問題の出題範囲を試験ごとに保持する。
///   実施回（"01_aki" など）は試験によって顔ぶれが違うため、
///   1 つの設定を共用せず ExamType ごとに分けて保存している。
/// ---------------------------------------------------------------------------
class ExamQuizFilterNotifier
    extends Notifier<Map<ExamType, ExamQuizFilter>> {
  static const _storageKey = 'exam_quiz_filters';

  @override
  Map<ExamType, ExamQuizFilter> build() {
    // 保存値の読み込みは非同期のため、まずは空で返してから差し替える
    _load();
    return const {};
  }

  /// 未設定の試験には既定値（全分野・全期間・10問のランダム演習）を返す
  ExamQuizFilter of(ExamType exam) => state[exam] ?? const ExamQuizFilter();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = {
        for (final entry in decoded.entries)
          ExamType.fromId(entry.key):
              ExamQuizFilter.fromJson(entry.value as Map<String, dynamic>),
      };
    } catch (error) {
      // 設定が壊れていても出題自体は既定値で続けられるようにする
      debugPrint('出題範囲の復元に失敗しました: $error');
    }
  }

  Future<void> update(ExamType exam, ExamQuizFilter filter) async {
    state = {...state, exam: filter};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        for (final entry in state.entries) entry.key.id: entry.value.toJson(),
      }),
    );
  }
}
