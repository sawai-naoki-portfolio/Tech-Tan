// 過去問データ（assets/<exam>/questions.json）の整合性を守るためのテスト。
// 出題・採点・図表表示はすべてこの JSON の形に依存しているため、
// 崩れた瞬間に気付けるようにしておく。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_tan/provider/exam_questions_provider.dart';
import 'package:tech_tan/utility/exam_question.dart';
import 'package:tech_tan/utility/exam_quiz_filter.dart';
import 'package:tech_tan/utility/exam_type.dart';

/// 各試験に最低限収録されているべき問題数
const _minimumQuestionCount = {
  ExamType.itPassport: 2900,
  ExamType.fe: 3300,
  ExamType.ap: 3400,
};

/// 元データ側で画像ファイルが欠けている問題。
/// アプリ側は ExamImageView が代替表示に倒すため実害はないが、
/// これ以上増えていないことを検知できるよう一覧にしておく。
const _knownMissingImages = {
  'assets/it_passport/images/28_haru/q1/01.png',
  'assets/ap/images/03_aki/q29/29.png',
};

void main() {
  final parsed = <ExamType, List<ExamQuestion>>{};

  setUpAll(() {
    for (final exam in ExamType.values) {
      final raw = File(exam.questionsAssetPath).readAsStringSync();
      parsed[exam] = parseExamQuestions((raw: raw, examId: exam.id));
    }
  });

  for (final exam in ExamType.values) {
    group(exam.label, () {
      List<ExamQuestion> questions() => parsed[exam]!;

      test('JSON として読み込め、問題数が下限を満たす', () {
        expect(questions().length,
            greaterThanOrEqualTo(_minimumQuestionCount[exam]!));
      });

      test('問題 ID に重複がない', () {
        final seen = <String>{};
        final duplicated = <String>[];
        for (final q in questions()) {
          if (!seen.add(q.id)) duplicated.add(q.id);
        }
        expect(duplicated, isEmpty, reason: '重複した問題ID: $duplicated');
      });

      test('正解は必ずア〜エのいずれかである', () {
        final invalid = questions()
            .where((q) => !kChoiceLabels.contains(q.answer))
            .map((q) => '${q.id}:${q.answer}')
            .toList();
        expect(invalid, isEmpty, reason: '不正な正解記号: $invalid');
      });

      test('選択肢は常にア・イ・ウ・エの 4 件に正規化される', () {
        final invalid = questions()
            .where((q) =>
                q.choices.length != 4 ||
                !const ListEquality()
                    .equals(q.choices.map((c) => c.label).toList(), kChoiceLabels))
            .map((q) => q.id)
            .toList();
        expect(invalid, isEmpty, reason: '選択肢の記号が揃っていない問題: $invalid');
      });

      // 公開版には収集元サイトが書いた解説を同梱していない（差し替え済みの解説だけを収録）。
      // そのため解説が空でないことは、差し替え済みの問題に限って確かめる。
      test('問題文が空でなく、差し替え済みの解説も空でない', () {
        final incomplete = questions()
            .where((q) =>
                q.question.trim().isEmpty ||
                (!q.isExplanationOriginal && q.explanation.trim().isEmpty))
            .map((q) => q.id)
            .toList();
        expect(incomplete, isEmpty, reason: '問題文または解説が空: $incomplete');
      });

      test('分野はアプリの絞り込みで使う 3 系のいずれかである', () {
        final unknown = questions()
            .map((q) => q.field)
            .toSet()
            .difference(kExamFields.toSet());
        expect(unknown, isEmpty, reason: '未対応の分野: $unknown');
      });

      test('実施回が和暦として解釈できる', () {
        final invalid = questions()
            .map((q) => q.season)
            .where((s) => s.year == 0)
            .map((s) => s.raw)
            .toSet();
        expect(invalid, isEmpty, reason: '解釈できない実施回: $invalid');
      });

      test('本文の無い選択肢には必ず図が伴う', () {
        // テキストも画像も無い選択肢が「4 件すべて」なら、
        // 選択肢は問題図の中に描かれている（データの想定内）。
        // 一部だけ空なら本文の取りこぼしなので検知する。
        final broken = questions().where((q) {
          final empty =
              q.choices.where((c) => !c.hasText && !c.hasImage).length;
          if (empty == 0 || empty == 4) return false;
          return true;
        }).map((q) => q.id).toList();
        expect(broken, isEmpty, reason: '一部の選択肢だけ中身が無い問題: $broken');
      });

      test('中身の無い 4 択には、代わりになる図が添えられている', () {
        final broken = questions()
            .where((q) =>
                q.choices.every((c) => !c.hasText && !c.hasImage) &&
                q.figures.isEmpty)
            .map((q) => q.id)
            .toList();
        expect(broken, isEmpty, reason: '選択肢も図も無い問題: $broken');
      });

      test('選択肢画像は 4 件そろっているか、1 件も無いかのどちらか', () {
        final broken = questions().where((q) {
          final withImage = q.choices.where((c) => c.hasImage).length;
          return withImage != 0 && withImage != 4;
        }).map((q) => q.id).toList();
        expect(broken, isEmpty, reason: '選択肢画像が中途半端な問題: $broken');
      });

      test('参照している画像がアセットに存在する', () {
        final missing = <String>{};
        for (final q in questions()) {
          for (final path in [
            ...q.figures,
            ...q.choices.map((c) => c.imagePath).nonNulls,
          ]) {
            if (!File(path).existsSync()) missing.add(path);
          }
        }
        expect(missing.difference(_knownMissingImages), isEmpty,
            reason: '新たに欠けた画像: ${missing.difference(_knownMissingImages)}');
      });

      test('画像を含むディレクトリが pubspec.yaml に登録されている', () {
        // Flutter のアセット指定は再帰しないため、
        // ディレクトリの登録漏れは実機でだけ画像が出ない事故になる。
        final pubspec = File('pubspec.yaml').readAsStringSync();
        final unregistered = <String>{};
        for (final q in questions()) {
          for (final path in [
            ...q.figures,
            ...q.choices.map((c) => c.imagePath).nonNulls,
          ]) {
            if (!File(path).existsSync()) continue;
            final dir = '${path.substring(0, path.lastIndexOf('/'))}/';
            if (!pubspec.contains('- $dir')) unregistered.add(dir);
          }
        }
        expect(unregistered, isEmpty,
            reason: 'pubspec.yaml に未登録のディレクトリ: $unregistered\n'
                '`dart run tool/generate_asset_list.dart` で再生成してください。');
      });
    });
  }
}

/// リストの要素が順序込みで一致するかを見る簡易マッチャー
class ListEquality {
  const ListEquality();

  bool equals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
