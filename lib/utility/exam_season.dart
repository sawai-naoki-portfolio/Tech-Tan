/// ---------------------------------------------------------------------------
/// ExamSeason
/// ─ 問題データの `season`（"01_aki" / "31_haru" / "23_toku" / "05_menjo" 等）を
///   和暦表示・並び順に変換するためのバリューオブジェクト。
///
/// 元号の判定について:
///   収録データの年番号は平成が 13〜31、令和が 01〜08 で重複しない。
///   （情報処理技術者試験の過去問は平成13年度以降を収録しているため、
///     12 以下は令和と判断して差し支えない。）
/// ---------------------------------------------------------------------------
class ExamSeason implements Comparable<ExamSeason> {
  /// 元データの生の値（"01_aki" など）。問題 ID の一部にも使う。
  final String raw;

  /// 元号込みの年（例: 令和元年 → 2019）
  final int year;

  /// 平成なら true
  final bool isHeisei;

  /// 元号を除いた年番号（令和元年 → 1）
  final int eraYear;

  /// 期の種別
  final SeasonTerm term;

  const ExamSeason._({
    required this.raw,
    required this.year,
    required this.isHeisei,
    required this.eraYear,
    required this.term,
  });

  /// "01_aki" のような文字列を解釈する。
  /// 想定外の形式でも落ちないよう、その場合は raw をそのまま表示に使う。
  factory ExamSeason.parse(String raw) {
    final parts = raw.split('_');
    final eraYear = parts.isEmpty ? null : int.tryParse(parts.first);
    final term = SeasonTerm.fromKey(parts.length > 1 ? parts[1] : '');

    if (eraYear == null) {
      return ExamSeason._(
        raw: raw,
        year: 0,
        isHeisei: false,
        eraYear: 0,
        term: term,
      );
    }

    // 13 以上は平成（平成 N 年 = 1988 + N）、12 以下は令和（令和 N 年 = 2018 + N）
    final isHeisei = eraYear >= 13;
    final year = isHeisei ? 1988 + eraYear : 2018 + eraYear;

    return ExamSeason._(
      raw: raw,
      year: year,
      isHeisei: isHeisei,
      eraYear: eraYear,
      term: term,
    );
  }

  /// 元号付きの年表記（例: "令和元年" / "平成31年"）
  String get eraLabel {
    if (year == 0) return raw;
    final era = isHeisei ? '平成' : '令和';
    // 元年は「1年」ではなく「元年」と書くのが正式
    final number = eraYear == 1 && !isHeisei ? '元' : '$eraYear';
    return '$era$number年';
  }

  /// 一覧やチップに出す表記（例: "令和元年 秋期"）
  String get label => year == 0 ? raw : '$eraLabel ${term.label}';

  /// 西暦を併記した表記（例: "令和元年 秋期（2019）"）
  String get labelWithYear => year == 0 ? raw : '$label（$year）';

  /// 新しい回ほど先に来る並び順（降順）で比較する
  @override
  int compareTo(ExamSeason other) {
    final byYear = other.year.compareTo(year);
    if (byYear != 0) return byYear;
    return other.term.order.compareTo(term.order);
  }

  @override
  bool operator ==(Object other) => other is ExamSeason && other.raw == raw;

  @override
  int get hashCode => raw.hashCode;

  @override
  String toString() => label;
}

/// 試験の実施区分
enum SeasonTerm {
  haru('haru', '春期', 1),
  toku('toku', '特別', 2),
  menjo('menjo', '免除', 3),
  aki('aki', '秋期', 4),
  unknown('', '', 0);

  const SeasonTerm(this.key, this.label, this.order);

  final String key;
  final String label;

  /// 同じ年内での並び順（春 → 特別 → 免除 → 秋）
  final int order;

  static SeasonTerm fromKey(String key) {
    return SeasonTerm.values.firstWhere(
      (t) => t.key == key,
      orElse: () => SeasonTerm.unknown,
    );
  }
}
