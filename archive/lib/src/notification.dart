import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart';

NotificationManager _notificationManager = NotificationManager._internal();
NotificationManager get notificationManager => _notificationManager;

class NotificationManager {
  FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  NotificationManager._internal();

  Future<bool?> initialize({
    SelectNotificationCallback? onSelectNotification,
    String? androidAppIcon,
    bool iosRequestAlertPermission = true,
    bool iosRequestSoundPermission = true,
    bool iosRequestBadgePermission = true,
    bool iosDefaultPresentAlert = true,
    bool iosDefaultPresentSound = true,
    bool iosDefaultPresentBadge = true,
    DidReceiveLocalNotificationCallback? iosOnDidReceiveLocalNotification,
  }) async {
    var android;
    if (androidAppIcon != null)
      android = AndroidInitializationSettings(androidAppIcon);
    var ios = IOSInitializationSettings(
        requestAlertPermission: iosRequestAlertPermission,
        requestSoundPermission: iosRequestSoundPermission,
        requestBadgePermission: iosRequestBadgePermission,
        defaultPresentAlert: iosDefaultPresentAlert,
        defaultPresentSound: iosDefaultPresentSound,
        defaultPresentBadge: iosDefaultPresentBadge,
        onDidReceiveLocalNotification: iosOnDidReceiveLocalNotification ??
            (int id, String? title, String? body, String? payload) async {});
    var macos = MacOSInitializationSettings(
      requestAlertPermission: iosRequestAlertPermission,
      requestSoundPermission: iosRequestSoundPermission,
      requestBadgePermission: iosRequestBadgePermission,
      defaultPresentAlert: iosDefaultPresentAlert,
      defaultPresentSound: iosDefaultPresentSound,
      defaultPresentBadge: iosDefaultPresentBadge,
    );

    return this._plugin.initialize(
          InitializationSettings(android: android, iOS: ios, macOS: macos),
          onSelectNotification:
              onSelectNotification ?? (String? payload) async {},
        );
  }

  Future<bool?>? iosRequestPermission({
    bool sound = false,
    bool alert = false,
    bool badge = false,
  }) {
    return _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          sound: sound,
          alert: alert,
          badge: badge,
        );
  }

  NativeNotification createNotification(
    int id, {
    String? title,
    String? body,
    String? payload,
  }) {
    var notification = NativeNotification._internal(_plugin, id);
    notification.title = title;
    notification.body = body;
    notification.payload = payload;
    return notification;
  }

  Future<List<PendingNotificationRequest>> pendingNotificationRequests() {
    return _plugin.pendingNotificationRequests();
  }

  Future<void> cancelAll() {
    return _plugin.cancelAll();
  }

  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() {
    return _plugin.getNotificationAppLaunchDetails();
  }

  /// Returns the list of active notifications shown by the application that
  /// haven't been dismissed/removed.
  ///
  /// This method is only applicable to Android 6.0 or newer and will throw an
  /// [PlatformException] when called on a device with an incompatible Android
  /// version.
  ///
  /// Not supported and return null on iOS.
  Future<List<ActiveNotification>?> activeNotifications() async {
    return await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.getActiveNotifications();
  }
}

class NativeNotification {
  FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  int _id;

  String? title;
  String? body;
  String? payload;

  Future<bool> get pending async =>
      (await notificationManager.pendingNotificationRequests())
          .any((e) => e.id == _id);

  NativeNotification._internal(this._plugin, this._id);

  Future<void> show({
    AndroidNotificationDetails? android,
    IOSNotificationDetails? ios,
    MacOSNotificationDetails? macos,
  }) {
    assert(
      android != null || ios != null || macos != null,
      "at least one platform specified details should be set",
    );
    return _plugin.show(
      _id,
      title,
      body,
      NotificationDetails(android: android, iOS: ios, macOS: macos),
      payload: payload,
    );
  }

  Future<void> zonedSchedule({
    required TZDateTime scheduledDate,
    AndroidNotificationDetails? android,
    IOSNotificationDetails? ios,
    MacOSNotificationDetails? macos,
    UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation =
        UILocalNotificationDateInterpretation.absoluteTime,
    bool androidAllowWhileIdle = false,
    DateTimeComponents? matchDateTimeComponents,
  }) {
    assert(
      android != null || ios != null || macos != null,
      "at least one platform specified details should be set",
    );
    return cancel().then(
      (_) => _plugin.zonedSchedule(
        _id,
        title,
        body,
        scheduledDate,
        NotificationDetails(android: android, iOS: ios, macOS: macos),
        payload: payload,
        uiLocalNotificationDateInterpretation:
            uiLocalNotificationDateInterpretation,
        androidAllowWhileIdle: androidAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      ),
    );
  }

  Future<void> showPeriodically({
    required RepeatInterval repeatInterval,
    AndroidNotificationDetails? android,
    IOSNotificationDetails? ios,
    MacOSNotificationDetails? macos,
    bool androidAllowWhileIdle = false,
  }) {
    assert(
      android != null || ios != null || macos != null,
      "at least one platform specified details should be set",
    );
    return _plugin.periodicallyShow(
      _id,
      title,
      body,
      repeatInterval,
      NotificationDetails(android: android, iOS: ios, macOS: macos),
      payload: payload,
      androidAllowWhileIdle: androidAllowWhileIdle,
    );
  }

  Future<void> cancel() {
    return _plugin.cancel(_id);
  }
}
