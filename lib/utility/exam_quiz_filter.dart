import 'dart:math';

import 'exam_question.dart';

/// ---------------------------------------------------------------------------
/// ExamQuizMode
/// ─ 実践問題（過去問）の出題方式。
///
/// 簿記の仕訳問題と違い、情報処理技術者試験の午前問題は
/// 「4 択 × 1 回分（IP は 100 問、FE / AP は 80 問）」という決まった形をしている。
/// そのため、分野を絞ったランダム演習だけでなく、
/// 1 回分を通しで解く「年度別演習」を用意している。
/// ---------------------------------------------------------------------------
enum ExamQuizMode {
  random(
    id: 'random',
    label: 'ランダム演習',
    description: '分野と年度を絞って、ランダムに出題します。',
  ),
  season(
    id: 'season',
    label: '年度別演習',
    description: '選んだ回の問題を、本番と同じ順番で通して解きます。',
  ),
  weak(
    id: 'weak',
    label: '苦手復習',
    description: '間違えたことのある問題だけを、ミスが多い順に出題します。',
  );

  const ExamQuizMode({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;

  static ExamQuizMode fromId(String? id) => ExamQuizMode.values.firstWhere(
        (m) => m.id == id,
        orElse: () => ExamQuizMode.random,
      );
}

/// 出題分野（大分類）。データの `classification` 先頭と一致させる。
const kExamFields = ['ストラテジ系', 'マネジメント系', 'テクノロジ系'];

/// ランダム演習・苦手復習で選べる出題数
const kQuestionCountOptions = [10, 20, 30, 50];

/// ---------------------------------------------------------------------------
/// ExamQuizFilter
/// ─ 実践問題の出題範囲。設定画面で組み立て、出題時に [apply] で絞り込む。
/// ---------------------------------------------------------------------------
class ExamQuizFilter {
  final ExamQuizMode mode;

  /// 出題する大分類（系）。空なら全分野。
  final Set<String> fields;

  /// 出題する中分類。空なら [fields] 配下すべて。
  final Set<String> categories;

  /// ランダム演習で対象にする実施回。空なら全期間。
  final Set<String> seasons;

  /// 年度別演習で選んだ実施回
  final String? targetSeason;

  /// ランダム演習・苦手復習の出題数
  final int questionCount;

  const ExamQuizFilter({
    this.mode = ExamQuizMode.random,
    this.fields = const {},
    this.categories = const {},
    this.seasons = const {},
    this.targetSeason,
    this.questionCount = 10,
  });

  ExamQuizFilter copyWith({
    ExamQuizMode? mode,
    Set<String>? fields,
    Set<String>? categories,
    Set<String>? seasons,
    String? targetSeason,
    bool clearTargetSeason = false,
    int? questionCount,
  }) {
    return ExamQuizFilter(
      mode: mode ?? this.mode,
      fields: fields ?? this.fields,
      categories: categories ?? this.categories,
      seasons: seasons ?? this.seasons,
      targetSeason:
          clearTargetSeason ? null : (targetSeason ?? this.targetSeason),
      questionCount: questionCount ?? this.questionCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.id,
        'fields': fields.toList(),
        'categories': categories.toList(),
        'seasons': seasons.toList(),
        'targetSeason': targetSeason,
        'questionCount': questionCount,
      };

  factory ExamQuizFilter.fromJson(Map<String, dynamic> json) {
    return ExamQuizFilter(
      mode: ExamQuizMode.fromId(json['mode'] as String?),
      fields: _toStringSet(json['fields']),
      categories: _toStringSet(json['categories']),
      seasons: _toStringSet(json['seasons']),
      targetSeason: json['targetSeason'] as String?,
      questionCount: json['questionCount'] as int? ?? 10,
    );
  }

  static Set<String> _toStringSet(Object? raw) =>
      raw is List ? raw.map((e) => e.toString()).toSet() : const {};

  /// 分野の絞り込みだけを適用する（一覧画面などで使う）
  bool matchesField(ExamQuestion question) {
    if (fields.isNotEmpty && !fields.contains(question.field)) return false;
    if (categories.isNotEmpty && !categories.contains(question.category)) {
      return false;
    }
    return true;
  }

  /// 条件に合う問題を、出題順まで含めて組み立てる。
  ///
  /// [mistakeCounts] は問題 ID → ミス回数。苦手復習でのみ使う。
  /// [random] はテストから乱数を固定するために差し込める。
  List<ExamQuestion> apply(
    List<ExamQuestion> all, {
    Map<String, int> mistakeCounts = const {},
    Random? random,
  }) {
    switch (mode) {
      case ExamQuizMode.season:
        // 1 回分を本番と同じ並び（問番号順）で返す。分野の絞り込みも効かせる。
        final target = targetSeason;
        if (target == null) return const [];
        return all
            .where((q) => q.seasonRaw == target && matchesField(q))
            .toList()
          ..sort((a, b) => a.number.compareTo(b.number));

      case ExamQuizMode.weak:
        // ミスが多い問題を優先し、同数ならランダムに散らす
        final rng = random ?? Random();
        final candidates = all
            .where((q) => (mistakeCounts[q.id] ?? 0) > 0 && matchesField(q))
            .toList()
          ..shuffle(rng);
        candidates.sort(
          (a, b) => (mistakeCounts[b.id] ?? 0).compareTo(mistakeCounts[a.id] ?? 0),
        );
        return candidates.take(questionCount).toList();

      case ExamQuizMode.random:
        final rng = random ?? Random();
        final candidates = all
            .where((q) =>
                matchesField(q) &&
                (seasons.isEmpty || seasons.contains(q.seasonRaw)))
            .toList()
          ..shuffle(rng);
        return candidates.take(questionCount).toList();
    }
  }

  /// 設定画面に出すサマリ（例: "テクノロジ系 / 全期間 / 10問"）
  String summary() {
    final fieldLabel = fields.isEmpty ? '全分野' : fields.join('・');
    switch (mode) {
      case ExamQuizMode.season:
        return '$fieldLabel / 1回分を通して出題';
      case ExamQuizMode.weak:
        return '$fieldLabel / 苦手な問題から$questionCount問';
      case ExamQuizMode.random:
        final seasonLabel = seasons.isEmpty ? '全期間' : '${seasons.length}回分';
        return '$fieldLabel / $seasonLabel / $questionCount問';
    }
  }
}
