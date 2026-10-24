import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/checked_exam_questions_notifier.dart';

/// 「あとで解き直す」に登録した実践問題の ID 集合
final checkedExamQuestionsProvider =
    NotifierProvider<CheckedExamQuestionsNotifier, Set<String>>(
  CheckedExamQuestionsNotifier.new,
);
