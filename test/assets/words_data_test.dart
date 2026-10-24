// 単語データ（assets/words.json）の整合性を守るためのテスト。
// 重複した見出し語や、読みガナ・説明文の欠落を混入させないための番人。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_tan/provider/words_provider.dart';
import 'package:tech_tan/utility/exam_type.dart';
import 'package:tech_tan/utility/word.dart';

/// アプリが謳っている収録語数の下限
const _minimumWordCount = 300;

/// ひらがな・長音・中黒・数字のみを許可する。
/// スラッシュは "SSL/TLS" → "えすえすえる/てぃーえるえす" のように
/// IT 用語の見出し語そのものに含まれるため例外的に認める。
final _yomiganaPattern = RegExp(r'^[ぁ-んー・/0-9]+$');

void main() {
  late List<Word> words;

  setUpAll(() {
    words = parseWords(File('assets/words.json').readAsStringSync());
  });

  test('JSON として読み込め、収録語数が下限を満たす', () {
    expect(words.length, greaterThanOrEqualTo(_minimumWordCount));
  });

  test('見出し語に重複がない', () {
    final seen = <String>{};
    final duplicates = <String>[];
    for (final w in words) {
      if (!seen.add(w.name)) duplicates.add(w.name);
    }
    expect(duplicates, isEmpty, reason: '重複した単語: ${duplicates.join('、')}');
  });

  test('すべての項目が埋まっている', () {
    final incomplete = words
        .where((w) =>
            w.name.trim().isEmpty ||
            w.description.trim().isEmpty ||
            w.yomigana.trim().isEmpty ||
            w.category.trim().isEmpty)
        .map((w) => w.name)
        .toList();
    expect(incomplete, isEmpty, reason: '未入力の項目がある単語: $incomplete');
  });

  test('読みガナはひらがなのみで構成されている', () {
    final invalid = words
        .where((w) => !_yomiganaPattern.hasMatch(w.yomigana))
        .map((w) => '${w.name}(${w.yomigana})')
        .toList();
    expect(invalid, isEmpty, reason: '読みガナの形式が不正: $invalid');
  });

  test('説明文の長さが妥当な範囲に収まっている', () {
    final tooShort =
        words.where((w) => w.description.length < 15).map((w) => w.name);
    final tooLong =
        words.where((w) => w.description.length > 200).map((w) => w.name);
    expect(tooShort, isEmpty, reason: '説明が短すぎる: $tooShort');
    expect(tooLong, isEmpty, reason: '説明が長すぎる: $tooLong');
  });

  test('カテゴリはアプリが扱う 3 試験のいずれかである', () {
    // 単語一覧のフィルターや単語テストの出題範囲は ExamType.label と照合するため、
    // ここがずれると単語がどこにも表示されなくなる。
    final supported = ExamType.values.map((e) => e.label).toSet();
    final unknown = words.map((w) => w.category).toSet().difference(supported);
    expect(unknown, isEmpty, reason: '未対応のカテゴリ: $unknown');
  });

  test('見出し語が試験をまたいで重複していない（差分モデルであること）', () {
    // 累積表示は「同じ語が複数のカテゴリに現れない」ことを前提にしている。
    // 重複すると、応用情報の一覧に同じ単語が 2 度並んでしまう。
    final byName = <String, List<String>>{};
    for (final w in words) {
      (byName[w.name] ??= []).add(w.category);
    }
    final duplicated = byName.entries
        .where((e) => e.value.toSet().length > 1)
        .map((e) => '${e.key}(${e.value.join('/')})')
        .toList();
    expect(duplicated, isEmpty, reason: '複数の試験に重複して登録された単語: $duplicated');
  });

  test('累積範囲で数えると上位試験ほど語数が多くなる', () {
    final counts = <ExamType, int>{
      for (final exam in ExamType.values)
        exam: words.where((w) => exam.cumulativeLabels.contains(w.category)).length,
    };
    expect(counts[ExamType.fe]!, greaterThan(counts[ExamType.itPassport]!));
    expect(counts[ExamType.ap]!, greaterThan(counts[ExamType.fe]!));
    // 応用情報の累積は全収録語（カスタム単語を除く）と一致する
    expect(counts[ExamType.ap], words.length);
  });

  test('どの試験にも十分な語数が収録されている', () {
    final counts = <String, int>{};
    for (final w in words) {
      counts[w.category] = (counts[w.category] ?? 0) + 1;
    }
    for (final exam in ExamType.values) {
      // 1回の単語テストは最大 20 問。単独の範囲でも出題できる数を確保する。
      expect(counts[exam.label] ?? 0, greaterThanOrEqualTo(50),
          reason: '${exam.label} の語数が少なすぎます');
    }
  });
}
