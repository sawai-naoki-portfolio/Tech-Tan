// 単語テストの出題生成のテスト。
// 「正解が必ず含まれる」「常に 4 択になる」を守れないと、テストとして成立しない。

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_tan/utility/generate_quiz_questions.dart';
import 'package:tech_tan/utility/word.dart';

List<Word> _words(int count) => List.generate(
      count,
      (i) => Word(
        name: '単語$i',
        yomigana: 'たんご$i',
        description: '説明$i',
        category: 'ITパスポート',
      ),
    );

void main() {
  test('指定した問題数だけ生成する', () {
    final pool = _words(30);
    final quiz = generateQuizQuestions(pool, pool,
        quizCount: 10, random: Random(0));
    expect(quiz.length, 10);
  });

  test('出題対象より多い問題数を指定しても、あるだけしか出さない', () {
    final pool = _words(3);
    final quiz =
        generateQuizQuestions(pool, pool, quizCount: 10, random: Random(0));
    expect(quiz.length, 3);
  });

  test('選択肢は必ず 4 つで、正解を含む', () {
    final pool = _words(30);
    final quiz =
        generateQuizQuestions(pool, pool, quizCount: 10, random: Random(1));
    for (final q in quiz) {
      expect(q.options.length, 4);
      expect(q.options, contains(q.word.name));
      expect(q.options.toSet().length, 4, reason: '選択肢が重複している');
    }
  });

  test('誤答候補が足りなくてもダミーで 4 択を保つ', () {
    final pool = _words(2);
    final quiz =
        generateQuizQuestions(pool, pool, quizCount: 2, random: Random(2));
    for (final q in quiz) {
      expect(q.options.length, 4);
      expect(q.options, contains(q.word.name));
    }
  });

  test('出題対象が空なら 1 問も作らない', () {
    expect(generateQuizQuestions(const [], _words(5)), isEmpty);
  });

  test('未回答は不正解、正しい語を選べば正解になる', () {
    final pool = _words(10);
    final quiz =
        generateQuizQuestions(pool, pool, quizCount: 1, random: Random(3));
    final question = quiz.single;

    expect(question.isCorrect, isFalse);
    question.userAnswer = question.word.name;
    expect(question.isCorrect, isTrue);
  });

  test('チェック済みの単語だけを出題しつつ、誤答は全単語から集められる', () {
    final all = _words(30);
    final checked = all.take(3).toList();
    final quiz =
        generateQuizQuestions(checked, all, quizCount: 3, random: Random(4));

    expect(quiz.length, 3);
    // 出題される単語はチェック済みのものだけ
    expect(
      quiz.every((q) => checked.map((w) => w.name).contains(q.word.name)),
      isTrue,
    );
    // 一方で選択肢には、チェックしていない単語も混ざりうる
    final optionNames = quiz.expand((q) => q.options).toSet();
    expect(optionNames.length, greaterThan(checked.length));
  });
}
