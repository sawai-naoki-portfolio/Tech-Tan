import 'dart:math';

import 'word.dart';
import 'word_test_question.dart';

/// ---------------------------------------------------------------------------
/// generateQuizQuestions
/// ─ quizPool（出題対象）と distractorPool（誤答候補）から、指定数のクイズ問題を生成する
/// ---------------------------------------------------------------------------
List<WordTestQuestion> generateQuizQuestions(
  List<Word> quizPool,
  List<Word> distractorPool, {
  int quizCount = 10,
  Random? random,
}) {
  final rng = random ?? Random();
  final quizWords = (List<Word>.from(quizPool)..shuffle(rng))
      .take(min(quizCount, quizPool.length))
      .toList();

  // 誤答候補の名前一覧は問題ごとに作り直す必要がないため、先に1度だけ用意する
  final distractorNames = distractorPool.map((w) => w.name).toList();

  return quizWords.map((word) {
    final options = <String>{word.name};

    // 正答以外からランダムに引いて、4択になるまで詰める
    if (distractorNames.length > 1) {
      var attempts = 0;
      final maxAttempts = distractorNames.length * 3;
      while (options.length < 4 && attempts < maxAttempts) {
        options.add(distractorNames[rng.nextInt(distractorNames.length)]);
        attempts++;
      }
    }
    // 候補が足りなかった場合はダミーで埋める
    var filler = 1;
    while (options.length < 4) {
      options.add('選択肢なし$filler');
      filler++;
    }

    final shuffled = options.toList()..shuffle(rng);
    return WordTestQuestion(word: word, options: shuffled);
  }).toList();
}
