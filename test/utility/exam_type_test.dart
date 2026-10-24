// 試験どうしの包含関係のテスト。
// words.json はカテゴリ間で重複しない「差分」で作られているため、
// ここを間違えると上級者に基礎用語が出題されなくなる。

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_tan/utility/exam_type.dart';

void main() {
  group('累積の範囲', () {
    test('ITパスポートは自分自身だけ', () {
      expect(ExamType.itPassport.cumulative, [ExamType.itPassport]);
      expect(ExamType.itPassport.cumulativeLabels, {'ITパスポート'});
    });

    test('基本情報は ITパスポート を含む', () {
      expect(ExamType.fe.cumulative, [ExamType.itPassport, ExamType.fe]);
      expect(ExamType.fe.cumulativeLabels, {'ITパスポート', '基本情報技術者'});
    });

    test('応用情報は 3 試験すべてを含む', () {
      expect(ExamType.ap.cumulative,
          [ExamType.itPassport, ExamType.fe, ExamType.ap]);
      expect(ExamType.ap.cumulativeLabels,
          {'ITパスポート', '基本情報技術者', '応用情報技術者'});
    });

    test('累積は基礎側から順に並ぶ', () {
      for (final exam in ExamType.values) {
        final levels = exam.cumulative.map((e) => e.level).toList();
        final sorted = [...levels]..sort();
        expect(levels, sorted, reason: '${exam.label} の並びが基礎順ではありません');
      }
    });

    test('自分より上位の試験は含まない', () {
      expect(ExamType.itPassport.cumulative, isNot(contains(ExamType.ap)));
      expect(ExamType.fe.cumulative, isNot(contains(ExamType.ap)));
    });
  });

  group('表示', () {
    test('下位のある試験は「まで」を付けて累積だと分かるようにする', () {
      expect(ExamType.itPassport.cumulativeLabel, 'ITパスポート');
      expect(ExamType.fe.cumulativeLabel, '基本情報技術者まで');
      expect(ExamType.ap.cumulativeLabel, '応用情報技術者まで');
    });

    test('内訳は略称でつなぐ（ITパスポートは内訳なし）', () {
      expect(ExamType.itPassport.cumulativeHint, isNull);
      expect(ExamType.fe.cumulativeHint, 'IP + FE');
      expect(ExamType.ap.cumulativeHint, 'IP + FE + AP');
    });
  });

  group('レベル', () {
    test('IP < FE < AP の順に広くなる', () {
      expect(ExamType.itPassport.level, lessThan(ExamType.fe.level));
      expect(ExamType.fe.level, lessThan(ExamType.ap.level));
    });

    test('id から復元でき、未知の値は ITパスポート に倒れる', () {
      expect(ExamType.fromId('ap'), ExamType.ap);
      expect(ExamType.fromId('unknown'), ExamType.itPassport);
      expect(ExamType.fromId(null), ExamType.itPassport);
    });
  });
}
