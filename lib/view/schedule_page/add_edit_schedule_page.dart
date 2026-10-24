import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../provider/schedule_provider.dart';
import '../../utility/responsive_sizes.dart';
import '../../utility/schedule_item.dart';

/// 2択のモードを区別するための列挙型
enum ScheduleMode { exam, study }

/// カレンダー上に置ける受験日の上限
const _maxExamDates = 3;

/// ---------------------------------------------------------------------------
/// AddEditSchedulePage
/// ─ スケジュールの新規作成・編集画面
/// ---------------------------------------------------------------------------
class AddEditSchedulePage extends ConsumerStatefulWidget {
  final ScheduleItem? scheduleItem;

  /// 新規作成時の初期日付。指定されていればその日付が開始日時になる。
  final DateTime? initialDate;

  const AddEditSchedulePage({super.key, this.scheduleItem, this.initialDate});

  @override
  ConsumerState<AddEditSchedulePage> createState() =>
      _AddEditSchedulePageState();
}

class _AddEditSchedulePageState extends ConsumerState<AddEditSchedulePage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tasksController = TextEditingController();

  /// 画面上に入力欄はないが、既存データを失わないよう保持しておく科目名
  String _subject = '';

  late DateTime _startTime;
  late DateTime _endTime;

  ScheduleMode _selectedMode = ScheduleMode.study;

  bool get _isEditing => widget.scheduleItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.scheduleItem;
    if (item != null) {
      // 既存スケジュール（編集モード）は保存されている内容をそのまま利用
      _titleController.text = item.title;
      _descriptionController.text = item.description;
      _tasksController.text = item.tasks.join(", ");
      _subject = item.subject;
      _startTime = item.startTime;
      _endTime = item.endTime;
      _selectedMode = item.isExamDate ? ScheduleMode.exam : ScheduleMode.study;
    } else {
      // 新規追加時は常に「勉強タスクを設定する」から始める
      _selectedMode = ScheduleMode.study;
      _startTime = widget.initialDate ?? DateTime.now();
      _endTime = _startTime.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tasksController.dispose();
    super.dispose();
  }

  /// 受験日として登録できる上限に達していないか確認する。
  /// 上限に達している場合はダイアログを出して false を返す。
  Future<bool> _canSelectExamMode() async {
    final schedules = ref.read(scheduleProvider);
    final now = DateTime.now();
    // 未来（今以降）の受験日スケジュールのみをカウント
    final examCount = schedules
        .where((e) =>
            e.isExamDate &&
            e.startTime.isAfter(now) &&
            e.id != widget.scheduleItem?.id)
        .length;

    // 既に受験日として登録済みのものを編集する場合は制限しない
    if (_isEditing && widget.scheduleItem!.isExamDate) return true;
    if (examCount < _maxExamDates) return true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("受験日の設定制限"),
        content: const Text("カレンダー上の受験日は$_maxExamDates件まで設定可能です。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("OK"),
          ),
        ],
      ),
    );
    return false;
  }

  Future<void> _pickDate(
      {required bool isStart, required bool withTime}) async {
    final base = isStart ? _startTime : _endTime;
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;

    var hour = base.hour;
    var minute = base.minute;
    if (withTime) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(base),
      );
      if (time == null || !mounted) return;
      hour = time.hour;
      minute = time.minute;
    }

    setState(() {
      final value =
          DateTime(picked.year, picked.month, picked.day, hour, minute);
      if (isStart) {
        _startTime = value;
        // 開始が終了を追い越したら終了も繰り下げる
        if (!_endTime.isAfter(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = value;
      }
    });
  }

  /// 入力内容から ScheduleItem を組み立てる。未入力があれば null を返す。
  ScheduleItem? _buildItem() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("タイトルを入力してください")),
      );
      return null;
    }
    final isExam = _selectedMode == ScheduleMode.exam;
    if (!isExam && !_endTime.isAfter(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("終了日時は開始日時より後にしてください")),
      );
      return null;
    }

    final tasks = _tasksController.text
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return ScheduleItem(
      id: widget.scheduleItem?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      subject: _subject,
      startTime: _startTime,
      endTime: isExam ? _startTime.add(const Duration(days: 7)) : _endTime,
      description: _descriptionController.text.trim(),
      tasks: isExam ? const [] : tasks,
      isCompleted: widget.scheduleItem?.isCompleted ?? false,
      isExamDate: isExam,
    );
  }

  Future<void> _save() async {
    final item = _buildItem();
    if (item == null) return;
    final notifier = ref.read(scheduleProvider.notifier);
    if (_isEditing) {
      await notifier.updateSchedule(item);
    } else {
      await notifier.addSchedule(item);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("削除の確認"),
            content: const Text("本当にこのスケジュールを削除しますか？"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("キャンセル"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("削除"),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await ref
        .read(scheduleProvider.notifier)
        .removeSchedule(widget.scheduleItem!.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isExam = _selectedMode == ScheduleMode.exam;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "スケジュール編集" : "スケジュール追加"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.paddingSmall),
        child: Column(
          children: [
            // 基本情報入力欄
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "タイトル"),
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "詳細"),
            ),
            const SizedBox(height: 16),
            // モード選択
            RadioGroup<ScheduleMode>(
              groupValue: _selectedMode,
              onChanged: (value) async {
                if (value == null) return;
                if (value == ScheduleMode.exam && !await _canSelectExamMode()) {
                  return;
                }
                if (!mounted) return;
                setState(() => _selectedMode = value);
              },
              child: const Row(
                children: [
                  Expanded(
                    child: RadioListTile<ScheduleMode>(
                      title: Text("勉強タスクを設定する"),
                      value: ScheduleMode.study,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<ScheduleMode>(
                      title: Text("受験日として設定する"),
                      value: ScheduleMode.exam,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // モードによって入力フィールドを切り替え
            if (isExam)
              // 受験日モード：日付を1つだけ選択
              ListTile(
                title:
                    Text("受験日: ${DateFormat('yyyy/MM/dd').format(_startTime)}"),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(isStart: true, withTime: false),
                ),
              )
            else ...[
              // 勉強タスクモード：開始日時／終了日時／タスク
              ListTile(
                title: Text(
                    "開始日時: ${DateFormat('yyyy/MM/dd').add_jm().format(_startTime)}"),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(isStart: true, withTime: true),
                ),
              ),
              ListTile(
                title: Text(
                    "終了日時: ${DateFormat('yyyy/MM/dd').add_jm().format(_endTime)}"),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(isStart: false, withTime: true),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.paddingSmall),
                child: TextField(
                  controller: _tasksController,
                  decoration: const InputDecoration(
                    labelText: "タスク（カンマ区切りで複数入力できます）",
                    hintText: "例: テクノロジ系を復習, 令和6年春期を1回分",
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text("保存"),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _delete,
                      child: const Text("削除"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text("保存"),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
