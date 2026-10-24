import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/exam_type_provider.dart';
import '../../utility/exam_type.dart';
import '../../utility/responsive_sizes.dart';
import 'word_card.dart';

/// ---------------------------------------------------------------------------
/// ExamSwitcher
/// ─ 「いま勉強している試験」を切り替えるセグメント。
///   テク単は 3 資格を 1 つのアプリで扱うため、どの試験を対象にしているかが
///   常に見えている必要がある。ここでの選択が実践問題・単語テスト・
///   ニュースの既定の範囲になる。
/// ---------------------------------------------------------------------------
class ExamSwitcher extends ConsumerWidget {
  const ExamSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(examTypeProvider);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: EdgeInsets.symmetric(
        horizontal: context.paddingSmall,
        vertical: context.paddingExtraSmall,
      ),
      child: Row(
        children: [
          for (final exam in ExamType.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _ExamChip(
                  exam: exam,
                  isSelected: exam == selected,
                  onTap: () =>
                      ref.read(examTypeProvider.notifier).select(exam),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExamChip extends StatelessWidget {
  final ExamType exam;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExamChip({
    required this.exam,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = examAccentColor(exam.label);

    return Material(
      color: isSelected ? accent : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? accent : theme.dividerColor,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                exam.shortLabel,
                style: TextStyle(
                  fontSize: context.fontSizeSmall,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                exam.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.fontSizeExtraSmall,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
