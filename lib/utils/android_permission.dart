import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:miru_app/utils/log.dart';
import 'package:permission_handler/permission_handler.dart';

Future<int> getAndroidVersion() async {
  if (Platform.isAndroid) {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final sdkInt = (await deviceInfo.androidInfo).version.sdkInt;
    logger.info('Android sdk version: $sdkInt');
    return sdkInt;
  }
  return 0;
}

Future<bool> requestFullStoragePermissions() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }
  var status1 = await Permission.manageExternalStorage.request();
  if (status.isGranted) {
    return true;
  } else if (status.isPermanentlyDenied) {
    openAppSettings();
  }
  return status.isGranted && status1.isGranted;
}

Future<bool> requestBasicStoragePermissions() async {
  if (Platform.isAndroid) {
    List<Permission> permissions = [
      Permission.storage,
    ];
    if (await getAndroidVersion() >= 33) {
      permissions.add(Permission.photos);
      permissions.add(Permission.audio);
      permissions.add(Permission.videos);
    }
    for (var permission in permissions) {
      var status = await permission.status;
      if (!status.isGranted) {
        status = await permission.request();
      }
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
      if (!status.isGranted) {
        return false;
      }
    }
  }
  return true;
}

Future<bool> requestNotificationPermissions() async {
  final androidVersion = await getAndroidVersion();
  if (androidVersion < 33) return true; // Android 13 以下版本不需要请求权限

  var notificationStatus = await Permission.notification.status;
  if (notificationStatus.isDenied) {
    await Permission.notification.request();
  } else if (notificationStatus.isPermanentlyDenied) {
    logger.info('Permission: Notification permission permanently denied.');
    openAppSettings();
  } else if (notificationStatus.isGranted) {
    logger.info('Permission: Notification permission granted.');
  }
  notificationStatus = await Permission.notification.status;
  return notificationStatus.isGranted;
}

Future<bool> isNotificationPermissionGranted() async {
  final androidVersion = await getAndroidVersion();
  if (androidVersion < 33) return true; // Android 13 以下版本不需要请求权限

  var notificationStatus = await Permission.notification.status;
  return notificationStatus.isGranted;
}
