import 'package:flutter/material.dart';

import 'load_memo.dart';
import 'responsive_sizes.dart';
import 'word.dart';

/// ---------------------------------------------------------------------------
/// MemoDisplay
/// ─ 各単語に対応するメモ内容を表示します（非キャッシュ）。
/// ---------------------------------------------------------------------------
class MemoDisplay extends StatelessWidget {
  final Word word;

  const MemoDisplay({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // 最低50pxの高さを確保
      constraints: const BoxConstraints(minHeight: 50),
      child: FutureBuilder<String>(
        future: loadMemo(word),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }
          if (snapshot.hasError) return const SizedBox();
          final memo = snapshot.data ?? '';
          if (memo.isNotEmpty) {
            return Text(
              'メモ: $memo',
              style: TextStyle(
                fontSize: context.fontSizeExtraSmall,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
