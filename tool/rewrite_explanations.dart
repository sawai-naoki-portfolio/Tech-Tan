// *****************************************************************************
// rewrite_explanations.dart
// -----------------------------------------------------------------------------
// 過去問の解説を、テク単で書き起こした文章へ差し替えるツール。
//
// 【なぜ差し替えるか】
// 問題文・選択肢・図表は IPA が公表した過去問題であり、営利・非営利を問わず
// 許諾や使用料なしで利用できる。一方、収録データに入っている解説は
// 収集元サイトが独自に書いたもので、IPA の利用条件の対象外になる。
// そのため解説だけを自前の文章へ順次置き換えている。
//
// 【使い方】
//   dart run tool/rewrite_explanations.dart <差し替えファイル.json>
//
// 差し替えファイルは「問題ID → 解説文」のマップ。
//   { "ap_07_haru_q1": "…", "fe_06_menjo_q3": "…" }
//
// 同じ問題が複数の回で出題されている場合は、指定した1件だけでなく
// 本文が一致する問題すべてに反映する（1,484問ぶんの手間が省ける）。
//
// 差し替えたレコードには explanationSource: "tech_tan" が付き、
// 進捗は tool/check_explanations.dart で確認できる。
// *****************************************************************************

import 'dart:convert';
import 'dart:io';

/// 自前の解説として最低限満たすべき長さ
const _minLength = 40;
const _maxLength = 1200;

/// 元の解説と一致してよい連続文字数の上限。
/// これを超えて同じ並びが残っていると、書き直しではなく写しになっている。
const _maxSharedRun = 25;

const _examDirs = {
  'it_passport': 'assets/it_passport/questions.json',
  'fe': 'assets/fe/questions.json',
  'ap': 'assets/ap/questions.json',
};

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('使い方: dart run tool/rewrite_explanations.dart <差し替えファイル.json>');
    exit(1);
  }

  final batch = (jsonDecode(File(args.first).readAsStringSync()) as Map)
      .map((k, v) => MapEntry(k as String, (v as String).trim()));
  if (batch.isEmpty) {
    stderr.writeln('差し替えファイルが空です。');
    exit(1);
  }

  // 全試験を読み込み、問題 ID と本文キーの索引を作る
  final files = <String, List<dynamic>>{};
  final byId = <String, Map<String, dynamic>>{};
  final byBody = <String, List<Map<String, dynamic>>>{};

  for (final entry in _examDirs.entries) {
    final list = jsonDecode(File(entry.value).readAsStringSync()) as List;
    files[entry.value] = list;
    for (final raw in list) {
      final q = raw as Map<String, dynamic>;
      byId['${entry.key}_${q['season']}_q${q['num']}'] = q;
      (byBody[_bodyKey(q)] ??= []).add(q);
    }
  }

  final errors = <String>[];
  var replaced = 0;
  var propagated = 0;

  batch.forEach((id, text) {
    final target = byId[id];
    if (target == null) {
      errors.add('$id: 該当する問題がありません');
      return;
    }
    if (text.length < _minLength) {
      errors.add('$id: 解説が短すぎます（${text.length}字）');
      return;
    }
    if (text.length > _maxLength) {
      errors.add('$id: 解説が長すぎます（${text.length}字）');
      return;
    }
    // 正解の記号に触れていない解説は、答えの根拠が読み取れない
    final answer = target['answer'] as String? ?? '';
    if (answer.isNotEmpty && !text.contains(answer)) {
      errors.add('$id: 正解「$answer」に言及していません');
      return;
    }
    // 元の文章をなぞっていないかを確認する
    final original = (target['explanation'] as String? ?? '');
    if (target['explanationSource'] != 'tech_tan') {
      final shared = _longestSharedRun(_squash(original), _squash(text));
      if (shared > _maxSharedRun) {
        errors.add('$id: 元の解説と $shared 文字連続で一致しています（書き直してください）');
        return;
      }
    }

    // 本文が同一の問題すべてに反映する
    for (final q in byBody[_bodyKey(target)]!) {
      q['explanation'] = text;
      q['explanationSource'] = 'tech_tan';
      if (!identical(q, target)) propagated++;
    }
    replaced++;
  });

  if (errors.isNotEmpty) {
    stderr.writeln('検証エラー:\n${errors.join('\n')}');
    exit(1);
  }

  for (final entry in files.entries) {
    File(entry.key)
        .writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(entry.value)}\n');
  }

  stdout.writeln('差し替え: $replaced件（同一問題への波及 $propagated件）');
}

/// 問題文と選択肢が同じなら同じ問題とみなすためのキー
String _bodyKey(Map<String, dynamic> q) {
  final options = (q['options'] as List? ?? const []).join('|');
  return '${q['question']}||$options'.replaceAll(RegExp(r'\s+'), '');
}

/// 比較前に空白と記号のゆれを落とす
String _squash(String s) => s.replaceAll(RegExp(r'[\s、。，．・「」（）()]'), '');

/// 2 つの文字列に共通する最長の連続部分の長さ
int _longestSharedRun(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  // 行方向だけを保持する動的計画法（解説どうしなので数千文字で収まる）
  var previous = List<int>.filled(b.length + 1, 0);
  var best = 0;
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    for (var j = 1; j <= b.length; j++) {
      if (a[i - 1] == b[j - 1]) {
        current[j] = previous[j - 1] + 1;
        if (current[j] > best) best = current[j];
      }
    }
    previous = current;
  }
  return best;
}
