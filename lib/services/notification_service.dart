import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class NotificationService {
  static Future<void> initialize() async {
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      debugPrint("Notification permission denied. Aborting background service.");
      return;
    }
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'helix_bg', // id
      'Helix Background Service', // name
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max, // importance must be at least LOW
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    try {
      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: 'helix_bg_v2',
          initialNotificationTitle: 'Helix Background Service',
          initialNotificationContent: 'Monitoring PC Status',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
        ),
      );
      await service.startService();
    } catch (e) {
      debugPrint('Android 16 Foreground Service Exception: $e');
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'helix_coding_agent',
      'Coding Agent',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    DartPluginRegistrant.ensureInitialized();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'helix_bg_v2', // id
      'Helix Background Service', // name
      description: 'This channel is used for important notifications.',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'helix_status',
      'PC Status Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    const storage = FlutterSecureStorage();
    bool wasOnline = false;

    Timer.periodic(const Duration(seconds: 15), (timer) async {
      try {
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            final ip = await storage.read(key: 'host_ip') ?? '100.117.245.88';
            bool isOnline = await _pingPort(ip, 8000);

            if (isOnline != wasOnline) {
              if (isOnline) {
                flutterLocalNotificationsPlugin.show(
                  id: 0,
                  title: 'Helix PC is Online!',
                  body: 'Connection established at $ip',
                  notificationDetails: platformChannelSpecifics,
                );
              } else {
                // Optional: show offline notification
                flutterLocalNotificationsPlugin.show(
                  id: 0,
                  title: 'Helix PC Offline',
                  body: 'Connection lost to $ip',
                  notificationDetails: platformChannelSpecifics,
                );
              }
              
              service.setForegroundNotificationInfo(
                title: "Helix Background Sync",
                content: isOnline ? "PC Online ($ip)" : "PC Offline",
              );
              
              wasOnline = isOnline;
            }
          }
        }
      } catch (e) {
        print('HELIX_DEBUG: ${e.toString()}');
        _logError(e.toString());
      }
    });
  } catch (e) {
    print('HELIX_DEBUG: ${e.toString()}');
    _logError(e.toString());
  }
}

Future<void> _logError(String error) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> logs = prefs.getStringList('system_logs') ?? [];
  logs.insert(0, '\${DateTime.now()}: $error');
  if (logs.length > 50) logs = logs.sublist(0, 50);
  await prefs.setStringList('system_logs', logs);
}

Future<bool> _pingPort(String host, int port) async {
  try {
    final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
    socket.destroy();
    return true;
  } catch (_) {
    return false;
  }
}
