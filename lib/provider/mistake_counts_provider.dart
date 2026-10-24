import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/mistake_count_notifier.dart';

/// 単語テストのミス回数（単語名 → 回数）
final mistakeCountsProvider =
    NotifierProvider<MistakeCountNotifier, Map<String, int>>(
  MistakeCountNotifier.new,
);
