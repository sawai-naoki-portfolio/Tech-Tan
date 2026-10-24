import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utility/word.dart';

/// ---------------------------------------------------------------------------
/// wordsProvider
/// ─ アセットの words.json から単語リストを非同期で読み込む Provider。
///   パースは compute() で別 isolate に逃がし、起動直後のカクつきを防ぐ。
/// ---------------------------------------------------------------------------
final wordsProvider = FutureProvider<List<Word>>((ref) async {
  final data = await rootBundle.loadString('assets/words.json');
  return compute(parseWords, data);
});

/// JSON 文字列を Word のリストへ変換する。
/// compute() へ渡すためトップレベル関数として定義している。
List<Word> parseWords(String raw) {
  final decoded = jsonDecode(raw) as List;
  return decoded
      .map((json) => Word.fromJson(json as Map<String, dynamic>))
      .toList();
}
