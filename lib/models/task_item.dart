import 'dart:convert';

enum TaskType { todo, reminder, note }

class TaskItem {
  final String id;
  final String title;
  final TaskType type;
  final DateTime createdAt;
  bool isCompleted;

  TaskItem({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.index,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'],
      title: json['title'],
      type: TaskType.values[json['type']],
      createdAt: DateTime.parse(json['createdAt']),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
