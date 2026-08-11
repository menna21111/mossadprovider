import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_notification_service.dart';

/// Facade used by the app entrypoint — delegates to [PushNotificationService].
class NotificationService {
  NotificationService._();

  static Future<void> initialize() => PushNotificationService.initialize();

  static Future<void> handleInitialMessage(RemoteMessage? message) =>
      PushNotificationService.handleInitialMessage(message);

  static Future<String?> getToken() => PushNotificationService.getToken();

  static Future<void> syncTokenWithBackend() =>
      PushNotificationService.syncTokenWithBackend();

  static Future<void> removeTokenFromBackend() =>
      PushNotificationService.removeTokenFromBackend();
}
