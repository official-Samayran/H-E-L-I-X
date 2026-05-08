import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  static Future<void> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.sensors,
      Permission.activityRecognition,
      Permission.ignoreBatteryOptimizations,
      Permission.notification,
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.nearbyWifiDevices,
    ].request();

    statuses.forEach((permission, status) {
      debugPrint("Permission $permission status: $status");
    });
  }
}
