import 'package:shared_preferences/shared_preferences.dart';

import 'word.dart';

/// ---------------------------------------------------------------------------
/// loadMemo
/// ─ SharedPreferences から指定された単語に対応するメモを読み込む
/// ---------------------------------------------------------------------------
Future<String> loadMemo(Word word) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('memo_${word.name}') ?? '';
}
