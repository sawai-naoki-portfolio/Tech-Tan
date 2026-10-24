/// ---------------------------------------------------------------------------
/// ExamType
/// ─ テク単が扱う 3 つの情報処理技術者試験。
///   ・アセットの配置（assets/<assetDir>/questions.json）
///   ・単語データの category 値
///   ・1 回分の試験の問題数
///   ・試験どうしの包含関係（[level]）
///   を 1 か所にまとめている。
///
/// 【単語データの持ち方について】
/// words.json はカテゴリ間で重複を持たない「差分」で作られている。
///   ITパスポート … 情報セキュリティ / IoT / KPI といった基礎
///   基本情報技術者 … スレッド / 仮想記憶 / デッドロックなど実装レベル
///   応用情報技術者 … フェイルソフト / B tree インデックスなど応用
/// つまり応用情報の受験者に必要なのは応用情報のぶんだけではなく、
/// その下位試験の単語も含めた累積になる。
/// この包含関係を [level] と [cumulative] で表現している。
/// ---------------------------------------------------------------------------
enum ExamType {
  itPassport(
    id: 'it_passport',
    label: 'ITパスポート',
    shortLabel: 'IP',
    assetDir: 'it_passport',
    questionsPerExam: 100,
    newsQuery: 'ITパスポート',
    level: 0,
  ),
  fe(
    id: 'fe',
    label: '基本情報技術者',
    shortLabel: 'FE',
    assetDir: 'fe',
    questionsPerExam: 80,
    newsQuery: '基本情報技術者',
    level: 1,
  ),
  ap(
    id: 'ap',
    label: '応用情報技術者',
    shortLabel: 'AP',
    assetDir: 'ap',
    questionsPerExam: 80,
    newsQuery: '応用情報技術者',
    level: 2,
  );

  const ExamType({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.assetDir,
    required this.questionsPerExam,
    required this.newsQuery,
    required this.level,
  });

  /// SharedPreferences などに保存する識別子
  final String id;

  /// 画面に出す正式名称。words.json の category とも一致する。
  final String label;

  /// チップなど狭い場所で使う略称
  final String shortLabel;

  /// assets 配下のディレクトリ名
  final String assetDir;

  /// 1 回分の試験に含まれる問題数（年度別演習の目安表示に使う）
  final int questionsPerExam;

  /// ニュース検索に使うキーワード
  final String newsQuery;

  /// 出題範囲の広さ。小さいほど基礎寄り（IP=0 / FE=1 / AP=2）。
  final int level;

  /// 問題データ JSON のパス
  String get questionsAssetPath => 'assets/$assetDir/questions.json';

  /// この試験を受けるうえで学習範囲に入る試験（自分自身と、より基礎の試験）。
  /// 基礎側から順に並ぶ。
  List<ExamType> get cumulative =>
      ExamType.values.where((e) => e.level <= level).toList();

  /// [cumulative] を単語データの category 値の集合にしたもの
  Set<String> get cumulativeLabels =>
      cumulative.map((e) => e.label).toSet();

  /// 累積であることが伝わる表示名（ITパスポートは下位が無いのでそのまま）
  String get cumulativeLabel => level == 0 ? label : '$labelまで';

  /// 累積範囲の内訳（例: "IP + FE + AP"）。1 つだけのときは null。
  String? get cumulativeHint => level == 0
      ? null
      : cumulative.map((e) => e.shortLabel).join(' + ');

  /// 保存済みの id から復元する。未知の値なら ITパスポートにフォールバックする。
  static ExamType fromId(String? id) {
    return ExamType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => ExamType.itPassport,
    );
  }
}
