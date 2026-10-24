import 'package:flutter/material.dart';

/// リスト名の最大文字数（UI が崩れない範囲に制限する）
const _maxCategoryNameLength = 30;

/// ---------------------------------------------------------------------------
/// showCategoryCreationDialog
/// ─ 新規リストを作成するための入力ダイアログを表示する。
///   戻り値は前後の空白を除いたリスト名。キャンセル時は null。
///   空文字・空白のみ・重複名は入力段階で弾くため、呼び出し側での検証は不要。
/// ---------------------------------------------------------------------------
Future<String?> showCategoryCreationDialog(
  BuildContext context, {
  Iterable<String> existingNames = const [],
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CategoryCreationDialog(
      existingNames: existingNames.toSet(),
    ),
  );
}

class _CategoryCreationDialog extends StatefulWidget {
  final Set<String> existingNames;

  const _CategoryCreationDialog({required this.existingNames});

  @override
  State<_CategoryCreationDialog> createState() =>
      _CategoryCreationDialogState();
}

class _CategoryCreationDialogState extends State<_CategoryCreationDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = "リスト名を入力してください");
      return;
    }
    if (widget.existingNames.contains(name)) {
      setState(() => _errorText = "同じ名前のリストが既にあります");
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("新規リストの作成"),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: _maxCategoryNameLength,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: "リスト名",
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("キャンセル"),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text("作成"),
        ),
      ],
    );
  }
}
