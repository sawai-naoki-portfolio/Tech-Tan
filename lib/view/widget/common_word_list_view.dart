import 'package:flutter/material.dart';

import '../../utility/word.dart';

/// ---------------------------------------------------------------------------
/// CommonWordListView
/// ─ 単語リストの表示を共通化するウィジェット。
///   引っ張って更新（onRefresh）や、ドラッグ＆ドロップでの並び替え
///   （isReorderable / onReorder）もサポートする。
/// ---------------------------------------------------------------------------
class CommonWordListView extends StatelessWidget {
  final List<Word> words;
  final Widget Function(BuildContext context, Word word) itemBuilder;
  final Future<void> Function()? onRefresh;
  final bool isReorderable;
  final void Function(int oldIndex, int newIndex)? onReorder;

  const CommonWordListView({
    super.key,
    required this.words,
    required this.itemBuilder,
    this.onRefresh,
    this.isReorderable = false,
    this.onReorder,
  }) : assert(!isReorderable || onReorder != null,
            'Reorderable の場合、onReorder コールバックは必須です。');

  @override
  Widget build(BuildContext context) {
    Widget list;
    if (isReorderable) {
      list = ReorderableListView.builder(
        itemCount: words.length,
        onReorderItem: onReorder!,
        itemBuilder: (context, index) {
          final word = words[index];
          return Container(
            key: ValueKey(word.name),
            child: itemBuilder(context, word),
          );
        },
      );
    } else {
      list = ListView.builder(
        itemCount: words.length,
        itemBuilder: (context, index) => itemBuilder(context, words[index]),
      );
    }
    if (onRefresh != null) {
      return RefreshIndicator(onRefresh: onRefresh!, child: list);
    }
    return list;
  }
}
