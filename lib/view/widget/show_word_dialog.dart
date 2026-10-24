import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../utility/memo_display.dart';
import '../../utility/responsive_sizes.dart';
import '../../utility/word.dart';
import 'show_memo_dialog.dart';
import 'word_card.dart';

/// ---------------------------------------------------------------------------
/// showWordDialog
/// ─ 単語の詳細ダイアログを表示する。
///   内部で StatefulBuilder を用いて、メモ更新後の再描画を最小限の範囲で行う。
/// ---------------------------------------------------------------------------
void showWordDialog(BuildContext context, Word word) {
  final GlobalKey dialogKey = GlobalKey();

  showDialog(
    context: context,
    builder: (context) {
      return RepaintBoundary(
        key: dialogKey,
        child: StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          word.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: context.fontSizeExtraLarge,
                          ),
                        ),
                        if (word.yomigana.isNotEmpty)
                          Text(
                            word.yomigana,
                            style: TextStyle(
                              fontSize: context.fontSizeExtraSmall,
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () async {
                      await _captureAndShareDialog(dialogKey, context, word);
                    },
                  ),
                ],
              ),
              content: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // どの試験で問われる単語かをひと目で分かるようにする
                      Chip(
                        label: Text(
                          word.category,
                          style: TextStyle(fontSize: context.fontSizeExtraSmall),
                        ),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: examAccentColor(word.category),
                        ),
                      ),
                      context.verticalSpaceExtraSmall,
                      Text(word.description),
                      context.verticalSpaceMedium,
                      MemoDisplay(word: word),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await showMemoDialog(context, word);
                    setState(() {});
                  },
                  child: const Text('メモを書く'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    FocusScope.of(context).unfocus();
                  },
                  child: const Text('閉じる'),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

/// 単語カードをキャプチャして画像ファイルに保存し、SNS 等へ共有する
Future<void> _captureAndShareDialog(
    GlobalKey key, BuildContext context, Word word) async {
  // await をまたぐ前に context 依存の値を取り出しておく
  final messenger = ScaffoldMessenger.of(context);
  final pixelRatio = MediaQuery.of(context).devicePixelRatio;

  try {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    // 画面のピクセル比に合わせて画像をキャプチャ
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData == null) return;
    final pngBytes = byteData.buffer.asUint8List();

    // 一時ディレクトリに画像を書き出す
    final tempDir = await getTemporaryDirectory();
    final file = await File(
            '${tempDir.path}/dialog_${DateTime.now().millisecondsSinceEpoch}.png')
        .create();
    await file.writeAsBytes(pngBytes);

    final shareText = '【${word.name}】\n${word.description}\n#テク単';

    // クリップボードにも共有テキストを保存しておく
    await Clipboard.setData(ClipboardData(text: shareText));

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: shareText),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('画像のキャプチャ/共有に失敗しました: $e')),
    );
  }
}
