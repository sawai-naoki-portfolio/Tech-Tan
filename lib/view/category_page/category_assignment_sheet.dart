// ============================================================================
// CategoryAssignmentSheet
// -----------------------------------------------------------------------------
// 指定された単語に対して、
// ・どのリストに所属させるか（チェックボックスで複数選択可能）
// ・「保存単語一覧」に載せるかどうか
// の割り当て状態を設定するためのモーダルシート。
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/categories_provider.dart';
import '../../provider/saved_items_provider.dart';
import '../../utility/responsive_sizes.dart';
import '../../utility/word.dart';
import '../widget/show_category_creation_dialog.dart';

class CategoryAssignmentSheet extends ConsumerStatefulWidget {
  final Word word;

  const CategoryAssignmentSheet({super.key, required this.word});

  @override
  ConsumerState<CategoryAssignmentSheet> createState() =>
      _CategoryAssignmentSheetState();
}

class _CategoryAssignmentSheetState
    extends ConsumerState<CategoryAssignmentSheet> {
  /// 各リスト名と、該当単語がそのリストに所属しているかの状態
  late Map<String, bool> _localAssignments;

  /// 「保存単語一覧」に登録するかのローカル状態
  late bool _localSaved;

  @override
  void initState() {
    super.initState();
    final currentCategories = ref.read(categoriesProvider);
    _localAssignments = {
      for (final cat in currentCategories)
        cat.name: cat.words.contains(widget.word.name)
    };
    // このシートは「保存する」導線から開くため、初期状態は ON にしておく
    _localSaved = true;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(context.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダ部分：対象単語の名称と「新規リスト追加」ボタン
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    '【${widget.word.name}】のリスト割当',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.fontSizeMedium,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final newCat = await showCategoryCreationDialog(
                      context,
                      existingNames: categories.map((c) => c.name),
                    );
                    if (newCat == null) return;
                    await ref
                        .read(categoriesProvider.notifier)
                        .addCategory(newCat);
                    if (!mounted) return;
                    setState(() => _localAssignments[newCat] = false);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新規リスト追加'),
                ),
              ],
            ),
            const Divider(),
            CheckboxListTile(
              title: const Text('保存単語一覧'),
              value: _localSaved,
              onChanged: (newVal) =>
                  setState(() => _localSaved = newVal ?? false),
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return CheckboxListTile(
                    title: Text(cat.name),
                    value: _localAssignments[cat.name] ?? false,
                    onChanged: (newVal) => setState(
                        () => _localAssignments[cat.name] = newVal ?? false),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // 完了ボタンを押すまで保存処理は行わない
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                for (final entry in _localAssignments.entries) {
                  await ref
                      .read(categoriesProvider.notifier)
                      .updateWordAssignment(
                        entry.key,
                        widget.word.name,
                        entry.value,
                      );
                }
                final savedItems = ref.read(savedItemsProvider.notifier);
                if (_localSaved) {
                  await savedItems.saveItem(widget.word.name);
                } else {
                  await savedItems.removeItem(widget.word.name);
                }
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text(
                '完了',
                style: TextStyle(fontSize: context.fontSizeMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
