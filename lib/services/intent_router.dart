import 'command_service.dart';

enum IntentType { systemCommand, generalQuery, localAITask }

class IntentRouter {
  final CommandService _commandService;

  IntentRouter(this._commandService);

  final List<String> _systemVerbs = ['/open', '/close', '/kill', 'system:', '/play', '/volume'];
  final List<String> _knownApps = ['spotify', 'chrome', 'discord', 'vscode'];

  Future<IntentType> routeInput(String input, bool isLocalAvailable) async {
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
        if (lowerInput.contains('open $app') || lowerInput.contains('close $app')) {
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

    // Default to active AI if ambiguous or not a command
    return isLocalAvailable ? IntentType.localAITask : IntentType.generalQuery;
  }
}
