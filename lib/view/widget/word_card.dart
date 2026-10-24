import 'package:flutter/material.dart';

import '../../utility/exam_type.dart';
import '../../utility/responsive_sizes.dart';
import '../../utility/word.dart';

/// 試験ごとのアクセント色。単語がどの試験向けかを一目で分かるようにする。
Color examAccentColor(String category) {
  switch (category) {
    case 'ITパスポート':
      return const Color(0xFF2E9E5B);
    case '基本情報技術者':
      return const Color(0xFF0B63CE);
    case '応用情報技術者':
      return const Color(0xFF8A3FD1);
    default:
      return const Color(0xFF6B7280);
  }
}

/// 表示用の短いラベル（"IP" / "FE" / "AP" / "自作"）
String examShortLabel(String category) {
  for (final exam in ExamType.values) {
    if (exam.label == category) return exam.shortLabel;
  }
  return category == Word.customCategory ? '自作' : '—';
}

/// ---------------------------------------------------------------------------
/// WordCard
/// ─ 各単語の情報（名前、説明、対象試験）を表示するカードウィジェット
/// ---------------------------------------------------------------------------
class WordCard extends StatelessWidget {
  final Word word;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets margin;

  const WordCard({
    super.key,
    required this.word,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.margin = const EdgeInsets.all(10.0),
  });

  @override
  Widget build(BuildContext context) {
    final accent = examAccentColor(word.category);
    return Card(
      margin: margin,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        // 左側に対象試験を示すバッジ（IP / FE / AP）を置く
        leading: CircleAvatar(
          backgroundColor: accent,
          child: Text(
            examShortLabel(word.category),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          word.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: context.fontSizeMedium,
          ),
        ),
        subtitle: Text(
          word.description,
          style: TextStyle(fontSize: context.fontSizeSmall),
        ),
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
