// ============================================================================
// AddWordDialog
// -----------------------------------------------------------------------------
// 「新規単語追加」ダイアログ。ユーザーが単語名・読みガナ・説明を入力すると、
// 入力内容から Word を生成して Navigator.pop で呼び出し元へ返す。
// 保存（永続化）は呼び出し側が CustomWordsNotifier 経由で行う。
// ============================================================================
import 'package:flutter/material.dart';

import '../../utility/word.dart';

class AddWordDialog extends StatefulWidget {
  const AddWordDialog({super.key});

  @override
  State<AddWordDialog> createState() => _AddWordDialogState();
}

class _AddWordDialogState extends State<AddWordDialog> {
  final _nameController = TextEditingController();
  final _yomiganaController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _yomiganaController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = '単語を入力してください');
      return;
    }
    Navigator.pop(
      context,
      Word(
        name: name,
        yomigana: _yomiganaController.text.trim(),
        description: _descriptionController.text.trim(),
        category: Word.customCategory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新規単語追加'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '単語',
                errorText: _errorText,
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
            ),
            TextField(
              controller: _yomiganaController,
              decoration: const InputDecoration(
                labelText: '読みガナ（任意）',
                hintText: 'ひらがなで入力すると検索しやすくなります',
              ),
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: '説明（任意）'),
              maxLines: null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('追加'),
        ),
      ],
    );
  }
}
