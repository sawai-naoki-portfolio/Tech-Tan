import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/checked_questions_notifier.dart';

/// 単語チェック問題に登録された単語名の集合
final checkedQuestionsProvider =
    NotifierProvider<CheckedQuestionsNotifier, Set<String>>(
    CheckedQuestionsNotifier.new);
