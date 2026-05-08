import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/theme_manager.dart';
import 'screens/home_screen.dart';

import 'services/base_connection_provider.dart';
import 'services/connection_service.dart';
import 'services/telemetry_service.dart';
import 'services/command_service.dart';
import 'services/intent_router.dart';

import 'services/notification_service.dart';
import 'widgets/adaptive_ui.dart';
import 'widgets/fps_monitor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'services/task_service.dart';
import 'services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  await NotificationService.initialize();
  await PermissionService.requestAllPermissions();
  
  if (Platform.isAndroid) {
    final prefs = await SharedPreferences.getInstance();
    final isSecure = prefs.getBool('secure_screen_protocol') ?? false;
    if (isSecure) {
      const platform = MethodChannel('com.example.helix/secure');
      try {
        await platform.invokeMethod('setSecure', {'secure': true});
      } catch (e) {
        debugPrint('Failed to set secure flag: $e');
      }
    }
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => BaseConnectionProvider()),
        
        ChangeNotifierProxyProvider<BaseConnectionProvider, ConnectionService>(
          create: (context) => ConnectionService(Provider.of<BaseConnectionProvider>(context, listen: false)),
          update: (_, base, previous) => previous ?? ConnectionService(base),
        ),
        
        ChangeNotifierProxyProvider<BaseConnectionProvider, TelemetryService>(
          create: (context) => TelemetryService(Provider.of<BaseConnectionProvider>(context, listen: false)),
          update: (_, base, previous) => previous ?? TelemetryService(base),
        ),

        Provider<CommandService>(
          create: (context) => CommandService(Provider.of<BaseConnectionProvider>(context, listen: false)),
        ),
        
        ChangeNotifierProvider(create: (_) => TaskService()),

        Provider<NotificationService>(create: (_) => NotificationService()),

        ProxyProvider2<CommandService, TaskService, IntentRouter>(
          update: (_, command, taskService, _) => IntentRouter(command, taskService),
        ),
      ],
      child: const HelixApp(),
    ),
  );
}

class HelixApp extends StatelessWidget {
  const HelixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return AdaptiveUI(
          scale: themeManager.uiScale,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                title: 'Helix Engine',
                debugShowCheckedModeBanner: false,
                theme: themeManager.themeData,
                home: const HomeScreen(),
                builder: (context, child) {
                  final mediaQueryData = MediaQuery.of(context);
                  Widget appChild = MediaQuery(
                    data: mediaQueryData.copyWith(
                      textScaler: TextScaler.linear(themeManager.uiScale),
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        fontFamily: themeManager.themeData.textTheme.bodyMedium?.fontFamily,
                        color: themeManager.textColor,
                      ),
                      child: child ?? const SizedBox(),
                    ),
                  );

                  if (themeManager.showFpsCounter) {
                    return FpsMonitor(child: appChild);
                  }
                  return appChild;
                },
              );
            }
          ),
        );
      },
    );
  }
}
