import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 検索欄の入力内容（デバウンス後の値）を保持する
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}
