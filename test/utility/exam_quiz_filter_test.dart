// 実践問題の出題範囲（ExamQuizFilter）のテスト。
// ここが崩れると「選んだ条件と違う問題が出る」という一番気付きにくい不具合になる。

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_tan/utility/exam_question.dart';
import 'package:tech_tan/utility/exam_quiz_filter.dart';
import 'package:tech_tan/utility/exam_type.dart';

ExamQuestion _question({
  required String season,
  required int num,
  String field = 'テクノロジ系',
  String category = 'セキュリティ',
}) {
  return ExamQuestion.fromJson({
    'season': season,
    'num': num,
    'question': '問題文$num',
    'options': const ['ア a', 'イ b', 'ウ c', 'エ d'],
    'images': const [],
    'classification': '$field » $category »小分類',
    'answer': 'ア',
    'explanation': '解説',
    'appearances': const [],
    'url': '',
  }, ExamType.ap);
}

void main() {
  final questions = [
    _question(season: '06_haru', num: 1),
    _question(season: '06_haru', num: 2, field: 'ストラテジ系', category: '法務'),
    _question(season: '06_haru', num: 3, field: 'マネジメント系', category: 'システム監査'),
    _question(season: '05_haru', num: 1),
    _question(season: '05_haru', num: 2, field: 'ストラテジ系', category: '企業活動'),
    _question(season: '31_haru', num: 1),
  ];

  group('ランダム演習', () {
    test('既定では全分野・全期間から出題数ぶんだけ選ぶ', () {
      const filter = ExamQuizFilter(questionCount: 4);
      final picked = filter.apply(questions, random: Random(0));
      expect(picked.length, 4);
    });

    test('分野を指定するとその系だけになる', () {
      const filter = ExamQuizFilter(
        fields: {'ストラテジ系'},
        questionCount: 10,
      );
      final picked = filter.apply(questions, random: Random(0));
      expect(picked.length, 2);
      expect(picked.every((q) => q.field == 'ストラテジ系'), isTrue);
    });

    test('中分類を指定するとさらに絞り込まれる', () {
      const filter = ExamQuizFilter(
        fields: {'ストラテジ系'},
        categories: {'法務'},
        questionCount: 10,
      );
      final picked = filter.apply(questions, random: Random(0));
      expect(picked.map((q) => q.category), ['法務']);
    });

    test('実施回を指定するとその回だけになる', () {
      const filter = ExamQuizFilter(
        seasons: {'05_haru'},
        questionCount: 10,
      );
      final picked = filter.apply(questions, random: Random(0));
      expect(picked.length, 2);
      expect(picked.every((q) => q.seasonRaw == '05_haru'), isTrue);
    });

    test('候補が出題数より少なくても、あるだけ返して落ちない', () {
      const filter = ExamQuizFilter(seasons: {'31_haru'}, questionCount: 50);
      expect(filter.apply(questions, random: Random(0)).length, 1);
    });
  });

  group('年度別演習', () {
    test('選んだ回の問題を、本番と同じ問番号順で返す', () {
      const filter = ExamQuizFilter(
        mode: ExamQuizMode.season,
        targetSeason: '06_haru',
      );
      final picked = filter.apply(questions);
      expect(picked.map((q) => q.number).toList(), [1, 2, 3]);
    });

    test('出題数の設定に関係なく 1 回分すべてを出す', () {
      const filter = ExamQuizFilter(
        mode: ExamQuizMode.season,
        targetSeason: '06_haru',
        questionCount: 1,
      );
      expect(filter.apply(questions).length, 3);
    });

    test('回を選んでいなければ何も出題しない', () {
      const filter = ExamQuizFilter(mode: ExamQuizMode.season);
      expect(filter.apply(questions), isEmpty);
    });
  });

  group('苦手復習', () {
    test('ミスが多い順に並ぶ', () {
      const filter = ExamQuizFilter(mode: ExamQuizMode.weak, questionCount: 10);
      final picked = filter.apply(
        questions,
        mistakeCounts: {
          'ap_06_haru_q1': 1,
          'ap_06_haru_q2': 5,
          'ap_05_haru_q1': 3,
        },
        random: Random(0),
      );
      expect(
        picked.map((q) => q.id).toList(),
        ['ap_06_haru_q2', 'ap_05_haru_q1', 'ap_06_haru_q1'],
      );
    });

    test('一度も間違えていなければ出題されない', () {
      const filter = ExamQuizFilter(mode: ExamQuizMode.weak);
      expect(filter.apply(questions, random: Random(0)), isEmpty);
    });

    test('分野の絞り込みも効く', () {
      const filter = ExamQuizFilter(
        mode: ExamQuizMode.weak,
        fields: {'ストラテジ系'},
        questionCount: 10,
      );
      final picked = filter.apply(
        questions,
        mistakeCounts: {'ap_06_haru_q1': 9, 'ap_06_haru_q2': 1},
        random: Random(0),
      );
      expect(picked.map((q) => q.id).toList(), ['ap_06_haru_q2']);
    });
  });

  group('保存と復元', () {
    test('JSON へ書き出して読み戻しても内容が変わらない', () {
      const filter = ExamQuizFilter(
        mode: ExamQuizMode.season,
        fields: {'テクノロジ系', 'ストラテジ系'},
        categories: {'セキュリティ'},
        seasons: {'06_haru'},
        targetSeason: '05_haru',
        questionCount: 30,
      );
      final restored = ExamQuizFilter.fromJson(filter.toJson());

      expect(restored.mode, filter.mode);
      expect(restored.fields, filter.fields);
      expect(restored.categories, filter.categories);
      expect(restored.seasons, filter.seasons);
      expect(restored.targetSeason, filter.targetSeason);
      expect(restored.questionCount, filter.questionCount);
    });

    test('壊れた／空の JSON でも既定値に落ちる', () {
      final restored = ExamQuizFilter.fromJson(const {});
      expect(restored.mode, ExamQuizMode.random);
      expect(restored.fields, isEmpty);
      expect(restored.questionCount, 10);
    });
  });

  test('copyWith で実施回の指定を明示的に消せる', () {
    const filter = ExamQuizFilter(targetSeason: '06_haru');
    expect(filter.copyWith(clearTargetSeason: true).targetSeason, isNull);
  });
}
