import 'package:flutter/material.dart';

import '../../../utility/exam_question.dart';
import '../../../utility/responsive_sizes.dart';
import '../../widget/exam_image_view.dart';

/// ---------------------------------------------------------------------------
/// ExamQuestionView
/// ─ 過去問 1 問の「問題文 → 選択肢 → 解説」を表示する共通ウィジェット。
///   簿記単で仕訳の解答 UI をクイズと問題詳細で共有していたのと同じ考え方で、
///   出題画面（ExamQuizPage）と問題詳細画面（ExamQuestionDetailPage）から使う。
///
/// 選択肢はデータの形に関わらず ExamChoice に正規化済みなので、
/// 「テキストのみ」「画像のみ」「図の中に 4 択が描かれている」のどれでも
/// 同じ描画ロジックで扱える。
/// ---------------------------------------------------------------------------
class ExamQuestionView extends StatefulWidget {
  final ExamQuestion question;

  /// 解答が確定したときに呼ばれる（正誤を渡す）
  final ValueChanged<bool>? onAnswered;

  /// true なら最初から正解と解説を開いた状態にする（復習用）
  final bool revealAnswer;

  const ExamQuestionView({
    super.key,
    required this.question,
    this.onAnswered,
    this.revealAnswer = false,
  });

  @override
  State<ExamQuestionView> createState() => _ExamQuestionViewState();
}

class _ExamQuestionViewState extends State<ExamQuestionView> {
  String? _selectedLabel;

  /// 解答済み、または最初から答えを見せるモードか
  bool get _isRevealed => _selectedLabel != null || widget.revealAnswer;

  void _select(String label) {
    if (_selectedLabel != null) return; // 二重回答を防ぐ
    setState(() => _selectedLabel = label);
    widget.onAnswered?.call(label == widget.question.answer);
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 出題回と分野
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _MetaChip(label: question.season.label, icon: Icons.event),
            _MetaChip(label: '問${question.number}', icon: Icons.tag),
            if (question.field.isNotEmpty)
              _MetaChip(label: question.field, icon: Icons.category),
          ],
        ),
        if (question.category.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            question.classificationLabel,
            style: TextStyle(
              fontSize: context.fontSizeExtraSmall,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 16),

        // 問題文
        SelectableText(
          question.question,
          style: TextStyle(
            fontSize: context.fontSizeMedium,
            height: 1.6,
          ),
        ),

        // 問題に添える図表（タップで拡大できる）
        for (final figure in question.figures)
          ExamImageView(assetPath: figure, maxHeight: 320),

        const SizedBox(height: 16),

        // 選択肢
        for (final choice in question.choices)
          _ChoiceTile(
            choice: choice,
            state: _stateOf(choice.label),
            onTap: _selectedLabel == null ? () => _select(choice.label) : null,
          ),

        if (_isRevealed) ...[
          const SizedBox(height: 16),
          _AnswerBanner(
            answer: question.answer,
            selected: _selectedLabel,
          ),
          const SizedBox(height: 16),
          _ExplanationSection(question: question),
        ],
      ],
    );
  }

  _ChoiceState _stateOf(String label) {
    if (!_isRevealed) return _ChoiceState.idle;
    if (label == widget.question.answer) return _ChoiceState.correct;
    if (label == _selectedLabel) return _ChoiceState.wrong;
    return _ChoiceState.dimmed;
  }
}

enum _ChoiceState { idle, correct, wrong, dimmed }

/// 選択肢 1 件。テキスト・画像のどちらか、または両方を表示する。
class _ChoiceTile extends StatelessWidget {
  final ExamChoice choice;
  final _ChoiceState state;
  final VoidCallback? onTap;

  const _ChoiceTile({
    required this.choice,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (Color border, Color background, Color badge) = switch (state) {
      _ChoiceState.correct => (
          Colors.green,
          Colors.green.withValues(alpha: 0.12),
          Colors.green,
        ),
      _ChoiceState.wrong => (
          theme.colorScheme.error,
          theme.colorScheme.error.withValues(alpha: 0.12),
          theme.colorScheme.error,
        ),
      _ChoiceState.dimmed => (
          theme.dividerColor,
          Colors.transparent,
          theme.colorScheme.onSurfaceVariant,
        ),
      _ChoiceState.idle => (
          theme.dividerColor,
          Colors.transparent,
          theme.colorScheme.primary,
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 記号バッジ（ア・イ・ウ・エ）
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badge,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    choice.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (choice.hasText)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            choice.text,
                            style: TextStyle(
                              fontSize: context.fontSizeMedium,
                              height: 1.5,
                            ),
                          ),
                        ),
                      if (choice.hasImage)
                        ExamImageView(
                          assetPath: choice.imagePath!,
                          maxHeight: 200,
                        ),
                      // 選択肢の中身が図にまとめられている場合は本文も画像も無い。
                      // その旨を書いておかないと空欄に見えてしまう。
                      if (!choice.hasText && !choice.hasImage)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '上の図の「${choice.label}」',
                            style: TextStyle(
                              fontSize: context.fontSizeSmall,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (state == _ChoiceState.correct)
                  const Icon(Icons.check_circle, color: Colors.green),
                if (state == _ChoiceState.wrong)
                  Icon(Icons.cancel, color: theme.colorScheme.error),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 正誤と正解記号を伝えるバナー
class _AnswerBanner extends StatelessWidget {
  final String answer;
  final String? selected;

  const _AnswerBanner({required this.answer, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // selected が null なのは「最初から答えを見せる」モードのとき
    final isCorrect = selected != null && selected == answer;
    final color = selected == null
        ? theme.colorScheme.primary
        : (isCorrect ? Colors.green : theme.colorScheme.error);

    final text = selected == null
        ? '正解は $answer です'
        : (isCorrect ? '正解！' : '不正解。正解は $answer です');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            selected == null
                ? Icons.lightbulb_outline
                : (isCorrect ? Icons.check_circle : Icons.cancel),
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: context.fontSizeMedium,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 解説と、同じ問題が出題された回の一覧
class _ExplanationSection extends StatelessWidget {
  final ExamQuestion question;

  const _ExplanationSection({required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '解説',
          style: TextStyle(
            fontSize: context.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            question.explanation.isEmpty ? '解説は登録されていません。' : question.explanation,
            style: TextStyle(
              fontSize: context.fontSizeSmall,
              height: 1.7,
            ),
          ),
        ),
        if (question.appearances.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'この問題が出題された回',
            style: TextStyle(
              fontSize: context.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '同じ内容が繰り返し問われています。優先して覚えましょう。',
            style: TextStyle(
              fontSize: context.fontSizeExtraSmall,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final appearance in question.appearances)
                Chip(
                  label: Text(
                    appearance,
                    style: TextStyle(fontSize: context.fontSizeExtraSmall),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 問題のメタ情報を表す小さなチップ
class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: context.fontSizeExtraSmall,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
