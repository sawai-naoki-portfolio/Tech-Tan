import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/search_query_notifier.dart';

/// 検索クエリの状態を管理する Provider
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);
