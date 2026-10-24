import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utility/exam_question.dart';
import '../../../utility/responsive_sizes.dart';

/// 過去問データの誤りを報告してもらう Google フォーム。
/// 実際の運用時は自分のフォーム URL に差し替えること。
const examFeedbackFormUrl = 'https://forms.gle/uF48zD3zLPVNuyU1A';

/// ---------------------------------------------------------------------------
/// QuestionInquiryButton
/// ─ 表示中の問題について問い合わせるためのボタン。
///   どの問題の話か分からないと調べようがないため、
///   問題 ID をコピーしてからでないとフォームへ進めないようにしている。
///   出典ページへのリンクも併せて出し、原典を確認できるようにする。
/// ---------------------------------------------------------------------------
class QuestionInquiryButton extends StatelessWidget {
  final ExamQuestion question;

  const QuestionInquiryButton({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.contact_support),
      tooltip: 'お問い合わせ',
      onPressed: () => _showInquiryDialog(context),
    );
  }

  Future<void> _launch(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('リンクを開けませんでした')),
      );
    }
  }

  void _showInquiryDialog(BuildContext context) {
    var isCopied = false;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('お問い合わせ'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '問題や解説に誤りがある場合は、以下フォームに「問題ID」と「正しい内容」を記載してください。',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(dialogContext)
                          .colorScheme
                          .secondaryContainer
                          .withValues(alpha: 0.5),
                      border: Border.all(
                          color: Theme.of(dialogContext).colorScheme.secondary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color:
                                Theme.of(dialogContext).colorScheme.secondary),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                '問題ID: ${question.id}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: dialogContext.fontSizeSmall,
                                ),
                              ),
                              Text(
                                question.title,
                                style: TextStyle(
                                    fontSize:
                                        dialogContext.fontSizeExtraSmall),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'コピー',
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: question.id));
                            setState(() => isCopied = true);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('問題IDをコピーしました')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: isCopied
                        ? () => _launch(dialogContext, examFeedbackFormUrl)
                        : null,
                    child: Text(
                      isCopied ? 'お問い合わせフォームへ移動' : '問題IDをコピーしてください',
                      style:
                          TextStyle(fontSize: dialogContext.fontSizeMedium),
                    ),
                  ),
                  if (question.url.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _launch(dialogContext, question.url),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(
                        '出典ページを開く',
                        style:
                            TextStyle(fontSize: dialogContext.fontSizeMedium),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('閉じる'),
              ),
            ],
          );
        });
      },
    );
  }
}
