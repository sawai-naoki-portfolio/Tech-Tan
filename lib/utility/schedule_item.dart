/// ---------------------------------------------------------------------------
/// ScheduleItem
/// ─ 学習スケジュール1件分のデータモデル。
///   受験日（isExamDate=true）と勉強予定の2種類を同じ型で表現する。
/// ---------------------------------------------------------------------------
class ScheduleItem {
  final String id;
  final String title;
  final String subject; // 科目・コース名
  final DateTime startTime;
  final DateTime endTime;
  final String description;
  final List<String> tasks; // タスクやマイルストーン
  final bool isCompleted;
  final bool isExamDate; // 受験日設定なら true

  ScheduleItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.description,
    this.tasks = const [],
    this.isCompleted = false,
    this.isExamDate = false,
  });

  /// コピー＆一部更新用ヘルパー
  ScheduleItem copyWith({
    String? title,
    String? subject,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    List<String>? tasks,
    bool? isCompleted,
    bool? isExamDate,
  }) {
    return ScheduleItem(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      tasks: tasks ?? this.tasks,
      isCompleted: isCompleted ?? this.isCompleted,
      isExamDate: isExamDate ?? this.isExamDate,
    );
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String? ?? '',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      description: json['description'] as String? ?? '',
      tasks: List<String>.from(json['tasks'] ?? []),
      isCompleted: json['isCompleted'] ?? false,
      isExamDate: json['isExamDate'] ?? false, // JSONに存在しなければ false
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'description': description,
        'tasks': tasks,
        'isCompleted': isCompleted,
        'isExamDate': isExamDate,
      };
}
