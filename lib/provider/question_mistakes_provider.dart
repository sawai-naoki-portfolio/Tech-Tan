import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/question_mistake_notifier.dart';

/// 実践問題のミス回数（問題 ID → 回数）
final questionMistakesProvider =
    NotifierProvider<QuestionMistakeNotifier, Map<String, int>>(
  QuestionMistakeNotifier.new,
);
