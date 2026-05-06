import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_item.dart';

class TaskService extends ChangeNotifier {
  static const String _tasksKey = 'helix_tasks';
  List<TaskItem> _tasks = [];
  
  List<TaskItem> get tasks => _tasks;
  List<TaskItem> get todos => _tasks.where((t) => t.type == TaskType.todo).toList();
  List<TaskItem> get notes => _tasks.where((t) => t.type == TaskType.note).toList();
  List<TaskItem> get reminders => _tasks.where((t) => t.type == TaskType.reminder).toList();

  TaskService() {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_tasksKey);
    if (tasksJson != null) {
      try {
        final List<dynamic> decoded = json.decode(tasksJson);
        _tasks = decoded.map((item) => TaskItem.fromJson(item)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading tasks: $e");
      }
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_tasksKey, encoded);
    notifyListeners();
  }

  void addTask(String title, TaskType type) {
    final task = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: type,
      createdAt: DateTime.now(),
    );
    _tasks.insert(0, task);
    _saveTasks();
  }

  void toggleTaskCompletion(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      _saveTasks();
    }
  }

  void removeTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _saveTasks();
  }
}
