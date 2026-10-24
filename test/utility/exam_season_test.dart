// 実施回（"01_aki" 等）の和暦変換と並び順のテスト。
// 平成 13〜31 年と令和 1〜8 年が同じ 2 桁で混在するため、判定を間違えると
// 「令和20年」のような存在しない表記が画面に出てしまう。

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_tan/utility/exam_season.dart';

void main() {
  group('和暦の解釈', () {
    test('12 以下は令和として扱う', () {
      final r1 = ExamSeason.parse('01_aki');
      expect(r1.isHeisei, isFalse);
      expect(r1.year, 2019);
      expect(r1.label, '令和元年 秋期');

      final r8 = ExamSeason.parse('08_haru');
      expect(r8.year, 2026);
      expect(r8.label, '令和8年 春期');
    });

    test('13 以上は平成として扱う', () {
      final h13 = ExamSeason.parse('13_haru');
      expect(h13.isHeisei, isTrue);
      expect(h13.year, 2001);
      expect(h13.label, '平成13年 春期');

      final h31 = ExamSeason.parse('31_haru');
      expect(h31.year, 2019);
      expect(h31.label, '平成31年 春期');
    });

    test('特別開催と午前免除の回も表記できる', () {
      expect(ExamSeason.parse('23_toku').label, '平成23年 特別');
      expect(ExamSeason.parse('05_menjo').label, '令和5年 免除');
    });

    test('西暦を併記できる', () {
      expect(ExamSeason.parse('06_haru').labelWithYear, '令和6年 春期（2024）');
    });

    test('想定外の形式でも落ちず、生の値をそのまま表示する', () {
      final broken = ExamSeason.parse('unknown');
      expect(broken.year, 0);
      expect(broken.label, 'unknown');
    });
  });

  group('並び順', () {
    test('新しい回が先に来る', () {
      final seasons = [
        ExamSeason.parse('20_aki'), // 平成20年 秋
        ExamSeason.parse('01_aki'), // 令和元年 秋
        ExamSeason.parse('31_haru'), // 平成31年 春
        ExamSeason.parse('06_haru'), // 令和6年 春
      ]..sort();

      expect(
        seasons.map((s) => s.raw).toList(),
        ['06_haru', '01_aki', '31_haru', '20_aki'],
      );
    });

    test('同じ年なら春 → 秋の順（新しい秋が先）', () {
      final seasons = [
        ExamSeason.parse('29_haru'),
        ExamSeason.parse('29_aki'),
      ]..sort();
      expect(seasons.map((s) => s.raw).toList(), ['29_aki', '29_haru']);
    });

    test('平成31年春と令和元年秋は同じ 2019 年だが、秋が先に来る', () {
      final seasons = [
        ExamSeason.parse('31_haru'),
        ExamSeason.parse('01_aki'),
      ]..sort();
      expect(seasons.map((s) => s.raw).toList(), ['01_aki', '31_haru']);
    });
  });
}
