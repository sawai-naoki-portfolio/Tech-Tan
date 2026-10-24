import 'word.dart';

/// ---------------------------------------------------------------------------
/// WordTestQuestion
/// ─ 単語テストの各問題を管理するデータクラス
/// ---------------------------------------------------------------------------
class WordTestQuestion {
  final Word word;
  final List<String> options;
  String? userAnswer; // ユーザーが選んだ回答

  WordTestQuestion({required this.word, required this.options});

  bool get isCorrect => userAnswer == word.name;
}
