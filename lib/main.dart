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

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  await NotificationService.initialize();
  
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
        
        ProxyProvider<CommandService, IntentRouter>(
          update: (_, command, __) => IntentRouter(command),
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
        return MaterialApp(
          title: 'Helix Engine',
          debugShowCheckedModeBanner: false,
          theme: themeManager.themeData,
          home: const HomeScreen(),
        );
      },
    );
  }
}
