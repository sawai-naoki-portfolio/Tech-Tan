import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/exam_quiz_filter_notifier.dart';
import '../utility/exam_quiz_filter.dart';
import '../utility/exam_type.dart';
import 'exam_type_provider.dart';

/// 実践問題の出題範囲（試験ごとに保持する）
final examQuizFilterProvider = NotifierProvider<ExamQuizFilterNotifier,
    Map<ExamType, ExamQuizFilter>>(
  ExamQuizFilterNotifier.new,
);

/// 選択中の試験の出題範囲だけを取り出したもの
final currentExamQuizFilterProvider = Provider<ExamQuizFilter>((ref) {
  final exam = ref.watch(examTypeProvider);
  return ref.watch(examQuizFilterProvider)[exam] ?? const ExamQuizFilter();
});
