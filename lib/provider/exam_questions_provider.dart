import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utility/exam_question.dart';
import '../utility/exam_season.dart';
import '../utility/exam_type.dart';
import 'exam_type_provider.dart';

/// ---------------------------------------------------------------------------
/// examQuestionsProvider
/// ─ 指定した試験の過去問 JSON（5〜7MB）を読み込む。
///   3 試験ぶんを常に抱えるとメモリも起動時間も無駄になるため、
///   family にして「実際に開いた試験だけ」を読むようにしている。
///   パースは compute() で別 isolate に逃がし、UI スレッドを止めない。
/// ---------------------------------------------------------------------------
final examQuestionsProvider =
    FutureProvider.family<List<ExamQuestion>, ExamType>((ref, exam) async {
  final data = await rootBundle.loadString(exam.questionsAssetPath);
  return compute(parseExamQuestions, (raw: data, examId: exam.id));
});

/// 選択中の試験の過去問
final currentExamQuestionsProvider =
    FutureProvider<List<ExamQuestion>>((ref) async {
  final exam = ref.watch(examTypeProvider);
  return ref.watch(examQuestionsProvider(exam).future);
});

/// JSON 文字列を ExamQuestion のリストへ変換する。
/// compute() へ渡すためトップレベル関数として定義している。
List<ExamQuestion> parseExamQuestions(({String raw, String examId}) message) {
  final exam = ExamType.fromId(message.examId);
  final decoded = jsonDecode(message.raw) as List;
  return decoded
      .map((json) => ExamQuestion.fromJson(json as Map<String, dynamic>, exam))
      .toList();
}

/// ---------------------------------------------------------------------------
/// examSeasonsProvider
/// ─ 選択中の試験に収録されている実施回を、新しい順に並べて返す。
///   出題範囲の設定画面と年度別演習の一覧で使う。
/// ---------------------------------------------------------------------------
final examSeasonsProvider =
    Provider.family<List<ExamSeason>, ExamType>((ref, exam) {
  final questions = ref.watch(examQuestionsProvider(exam)).value ?? const [];
  final seasons = <String, ExamSeason>{};
  for (final question in questions) {
    seasons.putIfAbsent(question.seasonRaw, () => question.season);
  }
  final list = seasons.values.toList()..sort();
  return List.unmodifiable(list);
});

/// ---------------------------------------------------------------------------
/// examCategoriesProvider
/// ─ 大分類（系）ごとの中分類一覧。出題範囲の設定画面で使う。
/// ---------------------------------------------------------------------------
final examCategoriesProvider =
    Provider.family<Map<String, List<String>>, ExamType>((ref, exam) {
  final questions = ref.watch(examQuestionsProvider(exam)).value ?? const [];
  final tree = <String, Set<String>>{};
  for (final question in questions) {
    if (question.field.isEmpty || question.category.isEmpty) continue;
    (tree[question.field] ??= <String>{}).add(question.category);
  }
  return Map.unmodifiable({
    for (final entry in tree.entries)
      entry.key: List<String>.unmodifiable(entry.value.toList()..sort()),
  });
});
