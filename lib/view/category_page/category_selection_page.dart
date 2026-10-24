import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ads/ad_manager.dart';
import '../../provider/categories_provider.dart';
import '../../utility/category.dart';
import '../../utility/responsive_sizes.dart';
import '../../utility/swipe_to_delete_card.dart';
import '../saved_items_page.dart';
import '../widget/show_category_creation_dialog.dart';
import 'category_items_page.dart';

/// ---------------------------------------------------------------------------
/// CategorySelectionPage
/// ─ 登録済みのリスト一覧を表示する画面。
///   各リストをタップすると、その中の単語一覧（CategoryItemsPage）へ遷移する。
/// ---------------------------------------------------------------------------
class CategorySelectionPage extends ConsumerStatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  ConsumerState<CategorySelectionPage> createState() =>
      _CategorySelectionPageState();
}

class _CategorySelectionPageState
    extends ConsumerState<CategorySelectionPage> {
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    // 固定の「保存単語一覧」タイル（デフォルト表示）
    final defaultSavedItemsTile = ListTile(
      key: const ValueKey('saved_items_default'),
      leading: const Icon(Icons.bookmark),
      title: const Text('保存単語一覧'),
      subtitle: const Text('保存された単語を表示します'),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SavedItemsPage()),
      ),
    );

    Widget listWidget;
    if (_isReordering) {
      // 並び替えモード：固定タイルは上部に固定し、ユーザー登録リストだけ並び替える
      listWidget = Column(
        children: [
          defaultSavedItemsTile,
          Expanded(
            child: ReorderableListView.builder(
              padding: EdgeInsets.symmetric(vertical: context.paddingMedium),
              itemCount: categories.length,
              // onReorderItem は削除位置を考慮した newIndex を渡してくれる
              onReorderItem: (oldIndex, newIndex) async {
                await ref
                    .read(categoriesProvider.notifier)
                    .reorderCategories(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final cat = categories[index];
                return ListTile(
                  key: ValueKey(cat.name),
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
                  title: Text(cat.name),
                  subtitle: Text('登録済み単語数: ${cat.words.length}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CategoryItemsPage(category: cat)),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else {
      listWidget = ListView(
        padding: EdgeInsets.symmetric(vertical: context.paddingMedium),
        children: [
          defaultSavedItemsTile,
          const Divider(),
          ...categories.map((cat) => SwipeToDeleteCard(
                keyValue: ValueKey(cat.name),
                onConfirm: () async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('削除確認'),
                          content: Text('リスト『${cat.name}』を削除してよろしいですか？'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('キャンセル'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('削除'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: () async {
                  await ref
                      .read(categoriesProvider.notifier)
                      .deleteCategory(cat.name);
                },
                child: ListTile(
                  title: Text(cat.name),
                  subtitle: Text('登録済み単語数: ${cat.words.length}'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CategoryItemsPage(category: cat)),
                  ),
                  onLongPress: () => _showCategoryOptions(cat),
                ),
              )),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('単語マイリスト'),
        centerTitle: true,
        actions: [
          if (_isReordering)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => setState(() => _isReordering = false),
            )
        ],
      ),
      body: listWidget,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newCat = await showCategoryCreationDialog(
            context,
            existingNames: categories.map((c) => c.name),
          );
          if (newCat == null) return;
          await ref.read(categoriesProvider.notifier).addCategory(newCat);
        },
        child: const Icon(Icons.add),
      ),
      // 一覧を眺める時間が長い画面のため、学習を妨げないバナーで表示する
      bottomNavigationBar: AdManager.bannerAdWidget(),
    );
  }

  void _showCategoryOptions(Category cat) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('リスト名の変更'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showRenameCategoryDialog(cat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('リスト削除'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('リスト削除'),
                    content: Text('リスト『${cat.name}』を削除してよろしいですか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('キャンセル'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('削除'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(categoriesProvider.notifier)
                      .deleteCategory(cat.name);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('並び替え'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _isReordering = true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameCategoryDialog(Category cat) async {
    final controller = TextEditingController(text: cat.name);
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('リスト名の変更'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 30,
            decoration: const InputDecoration(hintText: '新しいリスト名'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != cat.name) {
                  await ref
                      .read(categoriesProvider.notifier)
                      .updateCategory(cat.name, newName);
                }
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: const Text('変更'),
            ),
          ],
        ),
      );
    } finally {
      // ダイアログが閉じたら必ず破棄する（開くたびに積み上がるのを防ぐ）
      controller.dispose();
    }
  }
}
