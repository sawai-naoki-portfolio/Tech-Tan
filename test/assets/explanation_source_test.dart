// 解説の出典に関するテスト。
//
// 問題文・選択肢・図表は IPA が公表した過去問題で、営利・非営利を問わず
// 許諾なく利用できる。一方、収録データに元から入っていた解説は収集元サイトが
// 独自に書いたもので、IPA の利用条件の対象外になる。
// そのため解説だけをテク単の文章へ順次差し替えており、その進捗と品質をここで守る。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_tan/provider/exam_questions_provider.dart';
import 'package:tech_tan/utility/exam_question.dart';
import 'package:tech_tan/utility/exam_type.dart';

/// 差し替え済みの解説が満たすべき長さ
const _minLength = 40;
const _maxLength = 1200;

void main() {
  late List<ExamQuestion> all;

  setUpAll(() {
    all = [
      for (final exam in ExamType.values)
        ...parseExamQuestions((
          raw: File(exam.questionsAssetPath).readAsStringSync(),
          examId: exam.id,
        )),
    ];
  });

  test('差し替え済みの解説は長さが妥当な範囲に収まっている', () {
    final invalid = all
        .where((q) => !q.isExplanationOriginal)
        .where((q) =>
            q.explanation.length < _minLength ||
            q.explanation.length > _maxLength)
        .map((q) => '${q.id}(${q.explanation.length}字)')
        .toList();
    expect(invalid, isEmpty, reason: '長さが範囲外の解説: $invalid');
  });

  test('差し替え済みの解説は正解の記号に言及している', () {
    // 「なぜその選択肢が正解なのか」が読み取れない解説を防ぐ
    final missing = all
        .where((q) => !q.isExplanationOriginal)
        .where((q) => q.answer.isNotEmpty && !q.explanation.contains(q.answer))
        .map((q) => q.id)
        .toList();
    expect(missing, isEmpty, reason: '正解に触れていない解説: $missing');
  });

  test('差し替えた解説は、同じ問題すべてに反映されている', () {
    // 複数の回で出題された問題を片方だけ差し替えると、回によって解説が変わってしまう。
    // 差し替えツールは本文が一致する問題すべてに反映するので、その結果を確認する。
    //
    // 元データの時点で同一問題の解説が食い違っているものが 323 件あるため、
    // 検査対象は「差し替え済みを含む問題群」に限定する。
    final byBody = <String, List<ExamQuestion>>{};
    for (final q in all) {
      final key =
          '${q.question}||${q.choices.map((c) => c.text).join('|')}'
              .replaceAll(RegExp(r'\s+'), '');
      (byBody[key] ??= []).add(q);
    }
    final inconsistent = byBody.values
        .where((g) => g.length > 1)
        .where((g) => g.any((q) => !q.isExplanationOriginal))
        .where((g) => g.map((q) => q.explanation).toSet().length > 1)
        .map((g) => g.first.id)
        .toList();
    expect(inconsistent, isEmpty,
        reason: '差し替えが一部の回にしか反映されていない問題: $inconsistent');
  });

  test('自前化の進捗を記録する', () {
    final done = all.where((q) => !q.isExplanationOriginal).length;
    final rate = done / all.length * 100;
    // 進捗の可視化が目的なので、後戻りしていないことだけを確認する
    expect(done, greaterThan(0), reason: '差し替え済みの解説が 1 件もありません');
    printOnFailure('自前化: $done / ${all.length} 問');
    stdout.writeln(
        '  [解説の自前化] $done / ${all.length} 問（${rate.toStringAsFixed(1)}%）');
  });
}
