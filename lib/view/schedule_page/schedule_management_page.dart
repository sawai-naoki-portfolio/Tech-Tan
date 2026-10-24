import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../provider/schedule_provider.dart';
import '../../utility/responsive_sizes.dart';
import '../../utility/schedule_item.dart';
import 'add_edit_schedule_page.dart';

/// タスク一覧用の中間データクラス
class _TaskEntry {
  final String parentId;
  final String task;
  final DateTime date;

  _TaskEntry({
    required this.parentId,
    required this.task,
    required this.date,
  });
}

/// ---------------------------------------------------------------------------
/// ScheduleManagementPage
/// ─ カレンダー表示とタスク一覧表示を切り替えられる学習スケジュール管理画面
/// ---------------------------------------------------------------------------
class ScheduleManagementPage extends ConsumerStatefulWidget {
  const ScheduleManagementPage({super.key});

  @override
  ConsumerState<ScheduleManagementPage> createState() =>
      _ScheduleManagementPageState();
}

class _ScheduleManagementPageState extends ConsumerState<ScheduleManagementPage>
    with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // カレンダーでフォーカス中の日付・選択日
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  // カレンダー上のイベントを日付キーにグループ化
  Map<DateTime, List<ScheduleItem>> _groupEvents(
      List<ScheduleItem> scheduleList) {
    final data = <DateTime, List<ScheduleItem>>{};
    for (final event in scheduleList) {
      final day = DateTime(
          event.startTime.year, event.startTime.month, event.startTime.day);
      data.putIfAbsent(day, () => []).add(event);
    }
    return data;
  }

  List<ScheduleItem> _getEventsForDay(
      DateTime day, Map<DateTime, List<ScheduleItem>> grouped) {
    return grouped[DateTime(day.year, day.month, day.day)] ?? [];
  }

  /// 1件の ScheduleItem を、一覧表示用のタスク行に展開する。
  /// ・tasks があればその件数分
  /// ・tasks が空の勉強予定なら「勉強予定」1件
  /// ・受験日フラグが立っていれば「受験日」1件
  List<_TaskEntry> _expandToTaskEntries(ScheduleItem item) {
    final entries = <_TaskEntry>[];
    if (item.tasks.isNotEmpty) {
      for (final t in item.tasks) {
        entries
            .add(_TaskEntry(parentId: item.id, task: t, date: item.startTime));
      }
    } else if (!item.isExamDate) {
      entries.add(
          _TaskEntry(parentId: item.id, task: '勉強予定', date: item.startTime));
    }
    if (item.isExamDate) {
      entries.add(
          _TaskEntry(parentId: item.id, task: '受験日', date: item.startTime));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final scheduleList = ref.watch(scheduleProvider);
    final theme = Theme.of(context);

    final now = DateTime.now();
    final upcoming = scheduleList
        .where((e) => e.isExamDate && e.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final examCards = upcoming.take(3).map((event) {
      final days = event.startTime.difference(now).inDays + 1;
      return Expanded(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditSchedulePage(scheduleItem: event),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: theme.dividerColor),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_note,
                      color: theme.colorScheme.onSurfaceVariant, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: TextStyle(
                        fontSize: context.fontSizeMedium,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "受験日まで\n${days >= 0 ? days : 0} 日",
                    style: TextStyle(
                        fontSize: context.fontSizeMedium, height: 1.3),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();

    void showTaskOptions(_TaskEntry task) {
      final parent =
          ref.read(scheduleProvider).firstWhere((e) => e.id == task.parentId);

      showModalBottomSheet(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Wrap(children: [
            // 完了／未完了トグル
            ListTile(
              leading:
                  Icon(parent.isCompleted ? Icons.undo : Icons.check_circle),
              title: Text(parent.isCompleted ? '未完了に戻す' : '完了とする'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final updated =
                    parent.copyWith(isCompleted: !parent.isCompleted);
                await ref
                    .read(scheduleProvider.notifier)
                    .updateSchedule(updated);
              },
            ),

            // タスク削除メニュー
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('タスクを削除'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final notifier = ref.read(scheduleProvider.notifier);

                // 受験日の疑似タスクを消す
                if (task.task == '受験日') {
                  // 本来のタスクがなく受験日のみならスケジュール自体を削除
                  if (parent.tasks.isEmpty) {
                    await notifier.removeSchedule(parent.id);
                  } else {
                    // 勉強タスクも設定済み→受験日フラグだけオフ
                    await notifier
                        .updateSchedule(parent.copyWith(isExamDate: false));
                  }
                  return;
                }

                // 勉強予定の疑似タスクなら、スケジュール丸ごと削除
                if (task.task == '勉強予定') {
                  await notifier.removeSchedule(parent.id);
                  return;
                }

                // 本物のタスクならリストから名前だけ削除
                final newTasks = List<String>.from(parent.tasks)
                  ..remove(task.task);
                await notifier.updateSchedule(parent.copyWith(tasks: newTasks));
              },
            ),

            // キャンセル
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('キャンセル'),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ]),
        ),
      );
    }

    Widget buildAnimatedCalendar(Map<DateTime, List<ScheduleItem>> grouped) {
      const monthHeight = 350.0;
      const weekHeight = 135.0;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: _calendarFormat == CalendarFormat.month
              ? monthHeight
              : weekHeight,
          child: TableCalendar<ScheduleItem>(
            firstDay: DateTime.utc(2000),
            lastDay: DateTime.utc(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            onDaySelected: (sel, foc) {
              setState(() {
                _selectedDay = sel;
                _focusedDay = foc;
              });
            },
            calendarFormat: _calendarFormat,
            availableCalendarFormats: const {
              CalendarFormat.month: '',
              CalendarFormat.week: '',
            },
            onFormatChanged: (fmt) {
              setState(() => _calendarFormat = fmt);
            },
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
            eventLoader: (d) => _getEventsForDay(d, grouped),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.tertiary, shape: BoxShape.circle),
            ),
          ),
        ),
      );
    }

    /// タスクカードの共通ビルダー
    Widget buildTaskCard(_TaskEntry t, {bool showCheck = true}) {
      final parent =
          ref.read(scheduleProvider).firstWhere((e) => e.id == t.parentId);
      final labelColor = parent.isExamDate
          ? theme.colorScheme.error
          : theme.colorScheme.primary;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // タップで編集画面
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditSchedulePage(scheduleItem: parent),
            ),
          ),
          // 長押しでメニュー表示
          onLongPress: () => showTaskOptions(t),
          child: SizedBox(
            height: 72,
            child: Row(children: [
              // カラーバー
              Container(
                width: 6,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: labelColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),

              // チェックボタン（一覧側のみ表示）
              if (showCheck)
                IconButton(
                  icon: Icon(
                    parent.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: labelColor,
                    size: 28,
                  ),
                  onPressed: () async {
                    await ref.read(scheduleProvider.notifier).updateSchedule(
                        parent.copyWith(isCompleted: !parent.isCompleted));
                  },
                ),
              const SizedBox(width: 12),
              // メイン: スケジュールのタイトル / サブ: 日付 + タスク内容
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        decoration: parent.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: parent.isCompleted
                            ? theme.disabledColor
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('yyyy/MM/dd').format(t.date)} — ${t.task}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fontSizeMedium,
                        color: parent.isCompleted
                            ? theme.disabledColor
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ]),
          ),
        ),
      );
    }

    Widget calendarView() {
      final grouped = _groupEvents(scheduleList);

      // 選択日の「タスク」と「受験日」を1つのリストにまとめる
      final dayTasks = [
        for (final e in _getEventsForDay(_selectedDay, grouped))
          ..._expandToTaskEntries(e),
      ];

      return GestureDetector(
        // 上方向へのフリックで週表示に
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity;
          if (velocity == null) return;
          if (velocity < -300) {
            setState(() => _calendarFormat = CalendarFormat.week);
          } else if (velocity > 300) {
            setState(() => _calendarFormat = CalendarFormat.month);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ① 受験日カード
            if (examCards.isNotEmpty)
              Container(
                color: theme.colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(children: examCards),
              ),
            // ② カレンダー本体
            buildAnimatedCalendar(grouped),
            const Divider(),
            // ③ 選択日のタスク一覧
            Expanded(
              child: dayTasks.isNotEmpty
                  ? ListView.builder(
                      itemCount: dayTasks.length,
                      itemBuilder: (_, i) =>
                          buildTaskCard(dayTasks[i], showCheck: false),
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('当日のタスクがありません'),
                          SizedBox(height: 8),
                          Text('[+] を押してタスクを作成できます'),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    Widget taskListView() {
      // 全タスク取得（完了／未完了は関係なし）
      final allEntries = [
        for (final item in scheduleList) ..._expandToTaskEntries(item),
      ];

      // 完了／未完了を分ける
      final done = <_TaskEntry>[];
      final pending = <_TaskEntry>[];
      for (final e in allEntries) {
        final p = scheduleList.firstWhere((s) => s.id == e.parentId);
        (p.isCompleted ? done : pending).add(e);
      }

      // 未完了を日付で分類（過去／本日／未来）
      final now = DateTime.now();
      final todayKey = DateTime(now.year, now.month, now.day);
      final pastList = <_TaskEntry>[];
      final todayList = <_TaskEntry>[];
      final futureList = <_TaskEntry>[];
      for (final e in pending) {
        final key = DateTime(e.date.year, e.date.month, e.date.day);
        if (key.isBefore(todayKey)) {
          pastList.add(e);
        } else if (key == todayKey) {
          todayList.add(e);
        } else {
          futureList.add(e);
        }
      }

      // セクション作成ヘルパー
      ExpansionTile buildSection(
          String title, List<_TaskEntry> list, bool initiallyExpanded) {
        return ExpansionTile(
          title: Text(title,
              style: TextStyle(
                  fontSize: context.fontSizeMedium,
                  fontWeight: FontWeight.bold)),
          initiallyExpanded: initiallyExpanded,
          children: list.map(buildTaskCard).toList(),
        );
      }

      final children = <Widget>[
        if (pastList.isNotEmpty) buildSection('過去のタスク', pastList, true),
        if (todayList.isNotEmpty) buildSection('本日のタスク', todayList, true),
        if (futureList.isNotEmpty) buildSection('未来のタスク', futureList, true),
        if (done.isNotEmpty) buildSection('完了タスク', done, false),
      ];

      if (children.isEmpty) {
        return const Center(child: Text('タスクがありません'));
      }
      return ListView(children: children);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('スケジュール管理')),
      body: _selectedIndex == 0 ? calendarView() : taskListView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'タスク一覧',
          ),
        ],
        onTap: (idx) => setState(() => _selectedIndex = idx),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // 選択日に新規スケジュール作成へ
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddEditSchedulePage(initialDate: _selectedDay),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
