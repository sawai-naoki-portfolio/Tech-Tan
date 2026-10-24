// ExamQuestion.fromJson の正規化ロジックのテスト。
// 収録データは選択肢の持ち方が 3 通りあり、その差を吸収するのがこのクラスの役目。

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_tan/utility/exam_question.dart';
import 'package:tech_tan/utility/exam_type.dart';
import 'package:tech_tan/utility/search_normalize.dart';

Map<String, dynamic> _json({
  List<String> options = const [],
  List<String> images = const [],
  String classification = 'テクノロジ系 » セキュリティ »情報セキュリティ',
  int num = 12,
  String season = '01_aki',
}) {
  return {
    'season': season,
    'num': num,
    'question': '問題文',
    'options': options,
    'images': images,
    'classification': classification,
    'answer': 'ウ',
    'explanation': '解説',
    'appearances': const [],
    'url': 'https://example.com/q$num.html',
  };
}

void main() {
  group('選択肢の正規化', () {
    test('本文入りの 4 択は、記号を取り除いた本文になる', () {
      final q = ExamQuestion.fromJson(
        _json(options: ['ア あああ', 'イ いいい', 'ウ ううう', 'エ えええ']),
        ExamType.ap,
      );

      expect(q.choices.map((c) => c.label), kChoiceLabels);
      expect(q.choices.map((c) => c.text), ['あああ', 'いいい', 'ううう', 'えええ']);
      expect(q.choices.every((c) => !c.hasImage), isTrue);
    });

    test('記号だけの 4 択＋a/i/u/e の画像は、画像の選択肢になる', () {
      final q = ExamQuestion.fromJson(
        _json(
          options: ['ア', 'イ', 'ウ', 'エ'],
          images: [
            r'ap\images\01_aki\q12\12a.png',
            r'ap\images\01_aki\q12\12i.png',
            r'ap\images\01_aki\q12\12u.png',
            r'ap\images\01_aki\q12\12e.png',
          ],
        ),
        ExamType.ap,
      );

      // a=ア / i=イ / u=ウ / e=エ の順で割り当てられる
      expect(
        q.choices.map((c) => c.imagePath),
        [
          'assets/ap/images/01_aki/q12/12a.png',
          'assets/ap/images/01_aki/q12/12i.png',
          'assets/ap/images/01_aki/q12/12u.png',
          'assets/ap/images/01_aki/q12/12e.png',
        ],
      );
      // 選択肢に使った画像は問題図には回らない
      expect(q.figures, isEmpty);
    });

    test('"ア イ ウ エ" の 1 件は、中身の無い 4 択になり図が問題側に残る', () {
      final q = ExamQuestion.fromJson(
        _json(
          options: ['ア イ ウ エ'],
          images: [
            r'ap\images\01_aki\q12\12.png',
            r'ap\images\01_aki\q12\12a.png',
          ],
        ),
        ExamType.ap,
      );

      expect(q.choices.length, 4);
      expect(q.choices.every((c) => !c.hasText && !c.hasImage), isTrue);
      // "12a" は 1 枚だけなので選択肢画像ではなく「4択をまとめた図」として扱う
      expect(q.figures, [
        'assets/ap/images/01_aki/q12/12.png',
        'assets/ap/images/01_aki/q12/12a.png',
      ]);
    });

    test('問題図と選択肢画像が混在していても正しく振り分けられる', () {
      final q = ExamQuestion.fromJson(
        _json(
          options: ['ア', 'イ', 'ウ', 'エ'],
          images: [
            r'fe\images\01_aki\q12\12.png',
            r'fe\images\01_aki\q12\12a.png',
            r'fe\images\01_aki\q12\12i.png',
            r'fe\images\01_aki\q12\12u.png',
            r'fe\images\01_aki\q12\12e.png',
          ],
        ),
        ExamType.fe,
      );

      expect(q.figures, ['assets/fe/images/01_aki/q12/12.png']);
      expect(q.choices.every((c) => c.hasImage), isTrue);
    });

    test('論理回路の凡例画像（and/or/not）は問題図として扱う', () {
      final q = ExamQuestion.fromJson(
        _json(
          options: ['ア', 'イ', 'ウ', 'エ'],
          images: [
            r'fe\images\01_aki\q12\and.png',
            r'fe\images\01_aki\q12\or.png',
            r'fe\images\01_aki\q12\not.png',
          ],
        ),
        ExamType.fe,
      );

      expect(q.figures.length, 3);
      expect(q.choices.every((c) => !c.hasImage), isTrue);
    });
  });

  group('メタ情報', () {
    test('画像パスは assets 配下のスラッシュ区切りに変換される', () {
      final q = ExamQuestion.fromJson(
        _json(images: [r'it_passport\images\30_haru\q5\05.png']),
        ExamType.itPassport,
      );
      expect(q.figures.single, 'assets/it_passport/images/30_haru/q5/05.png');
    });

    test('問題 ID は試験・実施回・問番号から一意に決まる', () {
      final q = ExamQuestion.fromJson(
        _json(season: '03_haru', num: 42),
        ExamType.fe,
      );
      expect(q.id, 'fe_03_haru_q42');
    });

    test('分類は「系 ＞ 中分類 ＞ 小分類」に分解される', () {
      final q = ExamQuestion.fromJson(
        _json(classification: 'ストラテジ系 » 法務 »労働関連・取引関連法規'),
        ExamType.itPassport,
      );
      expect(q.field, 'ストラテジ系');
      expect(q.category, '法務');
      expect(q.topic, '労働関連・取引関連法規');
      expect(q.classificationLabel, 'ストラテジ系 ＞ 法務 ＞ 労働関連・取引関連法規');
    });

    test('分類が大分類だけでも壊れない（ITパスポートの一部データ）', () {
      final q = ExamQuestion.fromJson(
        _json(classification: 'テクノロジ系'),
        ExamType.itPassport,
      );
      expect(q.field, 'テクノロジ系');
      expect(q.category, isEmpty);
      expect(q.topic, isEmpty);
      expect(q.classificationLabel, 'テクノロジ系');
    });

    test('検索は問題文・選択肢・分類のいずれにもヒットする', () {
      final q = ExamQuestion.fromJson(
        _json(options: ['ア ファイアウォール', 'イ b', 'ウ c', 'エ d']),
        ExamType.ap,
      );
      // matches は正規化済みの検索語を受け取る契約（呼び出し側で正規化する）
      expect(q.matches(normalizeForSearch('問題')), isTrue);
      expect(q.matches(normalizeForSearch('ファイアウォール')), isTrue);
      expect(q.matches(normalizeForSearch('セキュリティ')), isTrue);
      expect(q.matches(normalizeForSearch('存在しない語')), isFalse);
    });

    test('表記が揺れていても検索でヒットする', () {
      final q = ExamQuestion.fromJson(
        _json(options: ['ア サーバの二重化', 'イ b', 'ウ c', 'エ d']),
        ExamType.ap,
      );
      // 収録側は「サーバ」、利用者の入力は「サーバー」でも引ける
      expect(q.matches(normalizeForSearch('サーバー')), isTrue);
      expect(q.matches(normalizeForSearch('さーば')), isTrue);
    });
  });
}
