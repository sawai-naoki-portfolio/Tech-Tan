/// ---------------------------------------------------------------------------
/// Category クラス
/// ─ ユーザーが登録するリスト。各リストは名前と所属する単語の名前リストを保持します。
/// ---------------------------------------------------------------------------
class Category {
  final String name;
  final List<String> words;

  Category({required this.name, List<String>? words}) : words = words ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'words': words,
      };

  factory Category.fromJson(Map<String, dynamic> json) {
    // 旧バージョンでは 'products' キーで保存していたため、両方を受け付ける
    final raw = json['words'] ?? json['products'] ?? const [];
    return Category(
      name: json['name'] as String,
      words: List<String>.from(raw as List),
    );
  }
}
