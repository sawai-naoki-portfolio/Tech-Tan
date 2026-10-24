import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utility/word.dart';
import 'custom_words_provider.dart';
import 'words_provider.dart';

/// ---------------------------------------------------------------------------
/// allWordsProvider
/// ─ アセット(JSON)からロードした単語とカスタム単語（ユーザー追加）を統合して返す
/// ---------------------------------------------------------------------------
final allWordsProvider = Provider<List<Word>>((ref) {
  final assetWords = ref.watch(wordsProvider).value ?? const <Word>[];
  final customWords = ref.watch(customWordsProvider);
  return [...assetWords, ...customWords];
});
