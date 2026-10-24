// *****************************************************************************
// check_explanations.dart
// -----------------------------------------------------------------------------
// 解説の自前化がどこまで進んだかを集計する。
//
//   dart run tool/check_explanations.dart          … 全体の進捗
//   dart run tool/check_explanations.dart --next   … 次に着手すべき問題を出力
//
// --next は「まだ差し替えていない一意な問題」を、出題回の新しい順に並べて
// 問題 ID を書き出す。差し替えファイルの下書きに使う。
// *****************************************************************************

import 'dart:convert';
import 'dart:io';

const _examDirs = {
  'it_passport': 'assets/it_passport/questions.json',
  'fe': 'assets/fe/questions.json',
  'ap': 'assets/ap/questions.json',
};

void main(List<String> args) {
  final showNext = args.contains('--next');

  final all = <Map<String, dynamic>>[];
  for (final entry in _examDirs.entries) {
    final list = jsonDecode(File(entry.value).readAsStringSync()) as List;
    for (final raw in list) {
      final q = Map<String, dynamic>.from(raw as Map);
      q['_exam'] = entry.key;
      q['_id'] = '${entry.key}_${q['season']}_q${q['num']}';
      all.add(q);
    }
  }

  // 本文が同じ問題はまとめて 1 件として数える
  final groups = <String, List<Map<String, dynamic>>>{};
  for (final q in all) {
    final options = (q['options'] as List? ?? const []).join('|');
    final key = '${q['question']}||$options'.replaceAll(RegExp(r'\s+'), '');
    (groups[key] ??= []).add(q);
  }

  final done = <List<Map<String, dynamic>>>[];
  final todo = <List<Map<String, dynamic>>>[];
  for (final g in groups.values) {
    (g.first['explanationSource'] == 'tech_tan' ? done : todo).add(g);
  }

  final doneQuestions = all.where((q) => q['explanationSource'] == 'tech_tan').length;

  stdout.writeln('■ 解説の自前化の進捗');
  stdout.writeln('  一意な問題: ${done.length} / ${groups.length} 件'
      '（${(done.length / groups.length * 100).toStringAsFixed(1)}%）');
  stdout.writeln('  収録問題ベース: $doneQuestions / ${all.length} 問'
      '（${(doneQuestions / all.length * 100).toStringAsFixed(1)}%）');

  final remainingChars = todo.fold<int>(
      0, (sum, g) => sum + (g.first['explanation'] as String).length);
  stdout.writeln('  残りの分量: 約 ${(remainingChars / 10000).round()} 万字');

  if (!showNext) return;

  // 新しい回から順に着手できるよう並べる
  int year(Map<String, dynamic> q) {
    final n = int.tryParse((q['season'] as String).split('_').first) ?? 0;
    return n >= 13 ? 1988 + n : 2018 + n;
  }

  todo.sort((a, b) {
    final byYear = year(b.first).compareTo(year(a.first));
    if (byYear != 0) return byYear;
    return (a.first['num'] as int).compareTo(b.first['num'] as int);
  });

  stdout.writeln('');
  stdout.writeln('■ 次に着手する問題（新しい回から 40 件）');
  for (final g in todo.take(40)) {
    final q = g.first;
    final shared = g.length > 1 ? '（同一問題 ${g.length}件に波及）' : '';
    stdout.writeln('  ${q['_id']}  ${q['answer']}  $shared');
  }
}
