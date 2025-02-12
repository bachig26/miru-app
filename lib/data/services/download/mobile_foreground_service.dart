import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:miru_app/utils/i18n.dart';
import 'package:miru_app/utils/log.dart';

// The callback function should always be a top-level or static function.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  // Called when the task is started.
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    logger.info('Mobile foreground service onStart(starter: ${starter.name})');
  }

  // Called based on the eventAction set in ForegroundTaskOptions.
  @override
  void onRepeatEvent(DateTime timestamp) {}

  // Called when the task is destroyed.
  @override
  Future<void> onDestroy(DateTime timestamp) async {
    logger.info('Mobile foreground service onDestroy');
  }
}

void _initService() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground_service',
      channelName: 'Foreground Service Notification',
      channelDescription:
          'This notification appears when the foreground service is running.',
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

Future<void> initForegroundService() async {
  _initService();
}

Future<ServiceRequestResult> startService() async {
  // logger.info('Mobile foreground service startService');
  if (await FlutterForegroundTask.isRunningService) {
    return FlutterForegroundTask.restartService();
  } else {
    return FlutterForegroundTask.startService(
      serviceId: 1,
      notificationTitle: 'download.download-manager'.i18n,
      notificationText: 'Tap to return to the app',
      notificationIcon: null,
      notificationButtons: null,
      notificationInitialRoute: '/settings/download/download_manager',
      callback: startCallback,
    );
  }
}

Future<bool> isRunningService() {
  return FlutterForegroundTask.isRunningService;
}

Future<ServiceRequestResult> stopService() {
  return FlutterForegroundTask.stopService();
}
