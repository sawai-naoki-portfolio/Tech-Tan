import 'exam_season.dart';
import 'exam_type.dart';
import 'search_normalize.dart';

/// 選択肢の記号。JSON の `answer` および `options` の接頭辞と一致させる。
const kChoiceLabels = ['ア', 'イ', 'ウ', 'エ'];

/// 選択肢画像のファイル名に使われている母音。
/// `23a.png` = ア / `23i.png` = イ / `23u.png` = ウ / `23e.png` = エ
const _choiceImageSuffixes = {'a': 'ア', 'i': 'イ', 'u': 'ウ', 'e': 'エ'};

/// 選択肢画像かどうかを判定する正規表現（"23a" → 問題番号 23 の ア）
final _choiceImagePattern = RegExp(r'^(\d+)([aiue])$');

/// ---------------------------------------------------------------------------
/// ExamQuestion
/// ─ 情報処理技術者試験の午前問題 1 問を表すデータモデル。
///
/// 収録データの選択肢は 3 パターンあり、どれも同じ形（[choices]）に正規化する。
///   A: options に本文入りの 4 択（"ア 〇〇" …）→ テキストのみの選択肢
///   B: options が記号のみ（"ア"…）＋ 選択肢画像 <番号>a/i/u/e.png → 画像の選択肢
///   C: options が ["ア イ ウ エ"] の 1 件 → 選択肢は問題図の中に描かれている。
///      記号だけのボタンを出し、図は問題文の下に表示する。
/// ---------------------------------------------------------------------------
class ExamQuestion {
  /// どの試験の問題か
  final ExamType exam;

  /// 実施回（"01_aki" などの生の値）
  final String seasonRaw;

  /// 問番号
  final int number;

  /// 問題文
  final String question;

  /// 正規化した 4 つの選択肢（常にア・イ・ウ・エの 4 件）
  final List<ExamChoice> choices;

  /// 問題文に添える図表画像（アセットパス）。選択肢画像はここには含まれない。
  final List<String> figures;

  /// 出題分野（"ストラテジ系" / "マネジメント系" / "テクノロジ系"）
  final String field;

  /// 中分類（"法務" など）。データに無ければ空文字。
  final String category;

  /// 小分類（"労働関連・取引関連法規" など）。データに無ければ空文字。
  final String topic;

  /// 正解の記号（"ア" 〜 "エ"）
  final String answer;

  /// 解説
  final String explanation;

  /// 解説をテク単で書き起こしたものかどうか。
  ///
  /// 問題文・選択肢・図表は IPA が公表した過去問題で、営利・非営利を問わず
  /// 許諾なく利用できる。一方、収集元サイトが独自に書いた解説は IPA の
  /// 利用条件の対象外なので、順次テク単の文章へ差し替えている。
  /// 差し替え済みのものだけ JSON に explanationSource: "tech_tan" が付く。
  final bool isExplanationOriginal;

  /// 同一問題が過去に出題された回の一覧
  final List<String> appearances;

  /// 出典（過去問道場の該当ページ）
  final String url;

  ExamQuestion({
    required this.exam,
    required this.seasonRaw,
    required this.number,
    required this.question,
    required this.choices,
    required this.figures,
    required this.field,
    required this.category,
    required this.topic,
    required this.answer,
    required this.explanation,
    required this.appearances,
    required this.url,
    this.isExplanationOriginal = true,
  });

  /// ミス回数やチェック状態の保存キーに使う一意な ID
  /// （例: "ap_01_aki_q24"）
  String get id => '${exam.id}_${seasonRaw}_q$number';

  /// 実施回の表示用オブジェクト
  ExamSeason get season => ExamSeason.parse(seasonRaw);

  /// 一覧に出す見出し（例: "令和元年 秋期 問24"）
  String get title => '${season.label} 問$number';

  /// 分野の表示（中分類・小分類があれば "＞" でつなぐ）
  String get classificationLabel => [
        field,
        if (category.isNotEmpty) category,
        if (topic.isNotEmpty) topic,
      ].join(' ＞ ');

  /// 検索用に正規化した問題文・選択肢・分類。
  /// 一覧の検索は 1 文字ごとに全問を走査するため、初回だけ計算して保持する。
  String get searchKey => _searchKey ??= normalizeForSearch([
        question,
        classificationLabel,
        ...choices.map((c) => c.text),
      ].join(' '));
  String? _searchKey;

  /// 正規化済みの検索語に一致するか
  bool matches(String normalizedQuery) => searchKey.contains(normalizedQuery);

  factory ExamQuestion.fromJson(Map<String, dynamic> json, ExamType exam) {
    final rawImages = (json['images'] as List? ?? const [])
        .map((e) => _toAssetPath(e as String))
        .toList();

    // 選択肢画像（<番号>a/i/u/e）が 4 つ揃っているものだけを選択肢として扱う。
    // 1 枚だけの "<番号>a.png" は「4 択をまとめて 1 枚に描いた図」なので問題図に回す。
    final choiceImages = _extractChoiceImages(rawImages);
    final figures = rawImages
        .where((path) => !choiceImages.containsValue(path))
        .toList(growable: false);

    final options = (json['options'] as List? ?? const [])
        .map((e) => e as String)
        .toList();
    final texts = _normalizeOptionTexts(options);

    final classification = (json['classification'] as String? ?? '')
        .split('»')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return ExamQuestion(
      exam: exam,
      seasonRaw: json['season'] as String? ?? '',
      number: json['num'] as int? ?? 0,
      question: (json['question'] as String? ?? '').trim(),
      choices: [
        for (final label in kChoiceLabels)
          ExamChoice(
            label: label,
            text: texts[label] ?? '',
            imagePath: choiceImages[label],
          ),
      ],
      figures: figures,
      field: classification.isNotEmpty ? classification[0] : '',
      category: classification.length > 1 ? classification[1] : '',
      topic: classification.length > 2 ? classification[2] : '',
      answer: json['answer'] as String? ?? '',
      explanation: (json['explanation'] as String? ?? '').trim(),
      isExplanationOriginal: json['explanationSource'] != 'tech_tan',
      appearances: (json['appearances'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      url: json['url'] as String? ?? '',
    );
  }

  /// JSON 中の画像パス（"ap\images\01_aki\q24\24.png"）を
  /// Flutter のアセットパス（"assets/ap/images/01_aki/q24/24.png"）に直す
  static String _toAssetPath(String raw) =>
      'assets/${raw.replaceAll(r'\', '/')}';

  /// 4 つ揃っている選択肢画像を記号 → パスの対応表にして返す。
  /// 揃っていなければ空の Map（＝すべて問題図として扱う）。
  static Map<String, String> _extractChoiceImages(List<String> paths) {
    // 問題番号ごとに、見つかった母音とパスを集める
    final grouped = <String, Map<String, String>>{};
    for (final path in paths) {
      final stem = _basenameWithoutExtension(path);
      final match = _choiceImagePattern.firstMatch(stem);
      if (match == null) continue;
      final number = match.group(1)!;
      final suffix = match.group(2)!;
      (grouped[number] ??= {})[suffix] = path;
    }

    for (final entry in grouped.values) {
      if (entry.length != _choiceImageSuffixes.length) continue;
      return {
        for (final suffix in _choiceImageSuffixes.entries)
          suffix.value: entry[suffix.key]!,
      };
    }
    return const {};
  }

  static String _basenameWithoutExtension(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot < 0 ? name : name.substring(0, dot);
  }

  /// options を「記号 → 本文」に正規化する。
  /// ・"ア 〇〇" → {"ア": "〇〇"}
  /// ・"ア"（記号のみ）→ {"ア": ""}（本文は画像側にある）
  /// ・["ア イ ウ エ"] の 1 件 → すべて空（選択肢は図の中）
  static Map<String, String> _normalizeOptionTexts(List<String> options) {
    if (options.length != kChoiceLabels.length) return const {};
    final result = <String, String>{};
    for (var i = 0; i < kChoiceLabels.length; i++) {
      final label = kChoiceLabels[i];
      var text = options[i].trim();
      if (text.startsWith(label)) {
        text = text.substring(label.length).trim();
      }
      result[label] = text;
    }
    return result;
  }
}

/// ---------------------------------------------------------------------------
/// ExamChoice
/// ─ 1 つの選択肢。テキストと画像はどちらか、または両方を持ちうる。
/// ---------------------------------------------------------------------------
class ExamChoice {
  /// 記号（"ア" 〜 "エ"）
  final String label;

  /// 選択肢の本文。画像だけの選択肢では空文字。
  final String text;

  /// 選択肢が画像で示される場合のアセットパス
  final String? imagePath;

  const ExamChoice({
    required this.label,
    required this.text,
    this.imagePath,
  });

  bool get hasText => text.isNotEmpty;

  bool get hasImage => imagePath != null;
}
