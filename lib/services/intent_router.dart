import 'command_service.dart';
import 'task_service.dart';
import 'connection_service.dart';
import '../models/task_item.dart';

enum IntentType { systemCommand, generalQuery, localAITask, taskExtraction }

class IntentRouter {
  final CommandService _commandService;
  final TaskService _taskService;

  IntentRouter(this._commandService, this._taskService);

  final List<String> _systemVerbs = [
    '/open',
    '/close',
    '/kill',
    'system:',
    '/play',
    '/volume',
  ];
  final List<String> _knownApps = ['spotify', 'chrome', 'discord', 'vscode'];

  Future<IntentType> routeInput(String input, ConnectionService connectionService) async {
    final lowerInput = input.trim().toLowerCase();

    // Command-First Validation
    bool isCommand = false;
    double confidence = 0.0;

    for (var verb in _systemVerbs) {
      if (lowerInput.startsWith(verb)) {
        isCommand = true;
        confidence = 1.0;
        break;
      }
    }

    if (!isCommand) {
      for (var app in _knownApps) {
        if (lowerInput.contains('open $app') ||
            lowerInput.contains('close $app')) {
          isCommand = true;
          confidence = 0.8;
          break;
        }
      }
    }

    if (isCommand && confidence > 0.5) {
      // Execute the system command
      await _commandService.executeSystemCommand(input);
      return IntentType.systemCommand;
    }

    // Task Extraction (NLP fallback)
    if (lowerInput.startsWith("remind me to ") ||
        lowerInput.contains("reminder:")) {
      String title = input
          .toLowerCase()
          .replaceAll("remind me to", "")
          .replaceAll("reminder:", "")
          .trim();
      _taskService.addTask(title, TaskType.reminder);
      return IntentType.taskExtraction;
    }

    if (lowerInput.contains("to do:") ||
        lowerInput.contains("todo:") ||
        lowerInput.contains("add to to do") ||
        lowerInput.contains("add to todo")) {
      String title = input
          .toLowerCase()
          .replaceAll("to do:", "")
          .replaceAll("todo:", "")
          .replaceAll("add to to do", "")
          .replaceAll("add to todo", "")
          .trim();
      _taskService.addTask(title, TaskType.todo);
      return IntentType.taskExtraction;
    }

    if (lowerInput.startsWith("note:") || lowerInput.contains("add to notes")) {
      String title = input
          .toLowerCase()
          .replaceAll("note:", "")
          .replaceAll("add to notes", "")
          .trim();
      _taskService.addTask(title, TaskType.note);
      return IntentType.taskExtraction;
    }

    // Default to active AI if ambiguous or not a command
    final mode = connectionService.masterModelMode;
    final isLocalAvailable = connectionService.isLocalAvailable;

    if (mode == MasterModelMode.local) {
      return IntentType.localAITask;
    } else if (mode == MasterModelMode.cloud) {
      return IntentType.generalQuery;
    } else {
      // Automatic
      return isLocalAvailable ? IntentType.localAITask : IntentType.generalQuery;
    }
  }

  bool isCodingIntent(String prompt) {
    final keywords = [
      'create project',
      'make an app',
      'write code',
      'flutter create',
      '/helix-code',
      'run',
      'execute'
    ];
    return keywords.any((k) => prompt.toLowerCase().contains(k));
  }
}
