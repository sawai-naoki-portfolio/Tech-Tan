// 検索の表記ゆれ吸収のテスト。
// 収録データは JIS 表記（センサ・サーバ）だが、利用者は長音付きで入力する。
// ここが崩れると「収録しているのに検索で出てこない」という一番気付きにくい形で壊れる。

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_tan/utility/search_normalize.dart';
import 'package:tech_tan/utility/word.dart';

Word _word(String name, {String yomigana = '', String description = '説明'}) =>
    Word(
      name: name,
      yomigana: yomigana,
      description: description,
      category: 'ITパスポート',
    );

void main() {
  group('正規化の規則', () {
    test('長音の有無を吸収する', () {
      expect(normalizeForSearch('センサー'), normalizeForSearch('センサ'));
      expect(normalizeForSearch('サーバー'), normalizeForSearch('サーバ'));
      expect(normalizeForSearch('コンピューター'), normalizeForSearch('コンピュータ'));
    });

    test('カタカナとひらがなを同一視する', () {
      expect(normalizeForSearch('センサ'), normalizeForSearch('せんさ'));
      expect(normalizeForSearch('ネットワーク'), normalizeForSearch('ねっとわーく'));
    });

    test('英字の大文字小文字を吸収する', () {
      expect(normalizeForSearch('IPアドレス'), normalizeForSearch('ipアドレス'));
      expect(normalizeForSearch('SQL'), 'sql');
    });

    test('全角の英数字を半角に寄せる', () {
      expect(normalizeForSearch('ＳＱＬ'), normalizeForSearch('SQL'));
      expect(normalizeForSearch('２進数'), normalizeForSearch('2進数'));
    });

    test('区切り記号と空白を無視する', () {
      expect(normalizeForSearch('SSL/TLS'), normalizeForSearch('ssltls'));
      expect(normalizeForSearch('ド・モルガン'), normalizeForSearch('どもるがん'));
      expect(normalizeForSearch('IP アドレス'), normalizeForSearch('IPアドレス'));
    });

    test('漢字はそのまま残り、カタカナ部分だけひらがなになる', () {
      expect(normalizeForSearch('情報セキュリティ'), '情報せきゅりてぃ');
    });

    test('え段以外の「い」は残す', () {
      // 「あい」「かい」などを縮めてしまうと別語と衝突しやすくなる
      expect(normalizeForSearch('アイコン'), 'あいこん');
      expect(normalizeForSearch('カイゼン'), 'かいぜん');
    });

    test('外来語のエーとエイの揺れを吸収する', () {
      // 問題文は「フェールセーフ」、収録語は「フェイルセーフ」と割れている
      expect(normalizeForSearch('フェールセーフ'), normalizeForSearch('フェイルセーフ'));
      expect(normalizeForSearch('フェールソフト'), normalizeForSearch('フェイルソフト'));
      expect(normalizeForSearch('メーン'), normalizeForSearch('メイン'));
    });

    test('記号だけの入力は空になる', () {
      expect(normalizeForSearch('ー・ '), isEmpty);
    });
  });

  group('Word の検索', () {
    test('長音付きで入力しても収録語が引ける', () {
      final sensor = _word('センサ', yomigana: 'せんさ');
      expect(sensor.matches(normalizeForSearch('センサー')), isTrue);
      expect(sensor.matches(normalizeForSearch('せんさー')), isTrue);
    });

    test('ひらがなで入力してもカタカナの見出し語が引ける', () {
      final word = _word('ファイアウォール', yomigana: 'ふぁいあうぉーる');
      expect(word.matches(normalizeForSearch('ふぁいあうぉーる')), isTrue);
      expect(word.matches(normalizeForSearch('ファイアウォール')), isTrue);
    });

    test('小文字で入力しても英字の見出し語が引ける', () {
      final word = _word('DNS', yomigana: 'でぃーえぬえす');
      expect(word.matches(normalizeForSearch('dns')), isTrue);
      expect(word.matches(normalizeForSearch('ＤＮＳ')), isTrue);
    });

    test('スラッシュ入りの見出し語を区切りなしで引ける', () {
      final word = _word('SSL/TLS', yomigana: 'えすえすえる/てぃーえるえす');
      expect(word.matches(normalizeForSearch('ssltls')), isTrue);
      expect(word.matches(normalizeForSearch('SSL')), isTrue);
    });

    test('読みガナ側でも一致する', () {
      final word = _word('可用性', yomigana: 'かようせい');
      expect(word.matches(normalizeForSearch('かようせい')), isTrue);
    });

    test('無関係な語には一致しない', () {
      final word = _word('センサ', yomigana: 'せんさ');
      expect(word.matches(normalizeForSearch('データベース')), isFalse);
    });

    test('検索キーは一度だけ計算され、同じ値を返す', () {
      final word = _word('センサ', yomigana: 'せんさ');
      expect(identical(word.searchKey, word.searchKey), isTrue);
    });
  });
}
