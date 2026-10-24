import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/custom_words_notifier.dart';
import '../utility/word.dart';

/// ユーザーが追加したカスタム単語を管理する Provider
final customWordsProvider =
    NotifierProvider<CustomWordsNotifier, List<Word>>(
    CustomWordsNotifier.new);
