import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/search_history_notifier.dart';

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
    SearchHistoryNotifier.new);
