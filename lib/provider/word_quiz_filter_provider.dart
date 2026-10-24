import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/word_quiz_filter_notifier.dart';

/// 単語テストの出題範囲（Word.category の集合）
final wordQuizFilterProvider =
    NotifierProvider<WordQuizFilterNotifier, Set<String>>(
  WordQuizFilterNotifier.new,
);
