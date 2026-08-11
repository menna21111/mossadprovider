import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:page_transition/page_transition.dart';

import '../../../app/functions.dart';
import '../../../app/navigator_key.dart';
import '../../../core/constants/mosaed_colors.dart';
import '../../../core/realtime/chat_session_registry.dart';
import '../../../features/notifications/data/notifications_repository.dart';
import '../../../features/notifications/presentation/notifications_screen.dart';
import '../../../firebase_options.dart';
import 'notification_manager.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static NotificationsRepository? _notificationsRepository;
  static void Function(Map<String, dynamic> data)? onForegroundPushData;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'mosaed_provider_channel',
    'Mosaed Provider Notifications',
    description: 'Notifications for Mosaed Provider app',
    importance: Importance.max,
    playSound: true,
  );

  static void bindNotificationsRepository(NotificationsRepository repository) {
    _notificationsRepository = repository;
  }

  static Future<String?> getToken() async {
    try {
      if (kIsWeb) return null;
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  static Future<void> initialize() async {
    try {
      debugPrint('Initializing PushNotificationService...');

      if (!await NotificationManager.isNotificationsEnabled()) {
        debugPrint('Push notifications disabled by user preference');
        return;
      }

      if (!kIsWeb) {
        await _messaging.requestPermission(alert: true, badge: true, sound: true);
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) async {
          if (response.payload != null && response.payload!.isNotEmpty) {
            _handlePayload(response.payload!);
          } else {
            _navigateToNotifications();
          }
        },
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM onMessage: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM onMessageOpenedApp: ${message.data}');
        _handleRemoteMessageNavigation(message);
      });

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      _messaging.onTokenRefresh.listen((_) => syncTokenWithBackend());

      await syncTokenWithBackend();

      debugPrint('PushNotificationService initialized');
    } catch (e) {
      debugPrint('Error initializing PushNotificationService: $e');
    }
  }

  static Future<void> handleInitialMessage(RemoteMessage? message) async {
    if (message == null) return;
    _handleRemoteMessageNavigation(message);
  }

  static Future<void> syncTokenWithBackend() async {
    if (_notificationsRepository == null) return;
    if (!await NotificationManager.isNotificationsEnabled()) return;

    final token = await getToken();
    if (token == null || token.isEmpty) return;

    try {
      await _notificationsRepository!.registerDeviceToken(token);
      debugPrint('FCM token registered with backend');
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  static Future<void> removeTokenFromBackend() async {
    if (_notificationsRepository == null) return;

    final token = await getToken();
    if (token == null || token.isEmpty) return;

    try {
      await _notificationsRepository!.deleteDeviceToken(token);
    } catch (e) {
      debugPrint('Failed to delete FCM token: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    final event = data['event']?.toString() ?? '';

    if (event == 'new_chat_message') {
      final requestId = data['request_id']?.toString();
      if (requestId != null && ChatSessionRegistry.isOpen(requestId)) {
        return;
      }
    }

    onForegroundPushData?.call(data);
    _showLocalNotification(message);

    final context = navigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? data['title']?.toString();
    final body = message.notification?.body ?? data['body']?.toString();
    final text = [title, body].whereType<String>().where((s) => s.isNotEmpty).join('\n');
    if (text.isNotEmpty) {
      AppFunctions.showsToast(text, MosaedColors.primary, context);
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    final title = notification?.title ?? data['title']?.toString();
    final body = notification?.body ?? data['body']?.toString();
    if (title == null && body == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotificationsPlugin.show(
      notification?.hashCode ?? Object.hash(title, body),
      title,
      body,
      details,
      payload: data['route']?.toString() ?? '',
    );
  }

  static void _handlePayload(String payload) {
    if (payload.isEmpty) {
      _navigateToNotifications();
      return;
    }
    _navigateTo(payload);
  }

  static void _handleRemoteMessageNavigation(RemoteMessage message) {
    final route = message.data['route']?.toString();
    if (route != null && route.isNotEmpty) {
      _navigateTo(route);
    } else {
      _navigateToNotifications();
    }
  }

  static void _navigateTo(String route) {
    if (navigatorKey.currentState == null) return;
    navigatorKey.currentState!.pushNamed(route);
  }

  static void _navigateToNotifications() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    AppFunctions.navigateTo(
      context,
      const NotificationsScreen(),
      PageTransitionType.rightToLeft,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final backgroundPlugin = FlutterLocalNotificationsPlugin();

  const androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwinInitializationSettings = DarwinInitializationSettings();
  const initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
    iOS: darwinInitializationSettings,
  );

  await backgroundPlugin.initialize(initializationSettings);

  final notification = message.notification;
  final data = message.data;
  final title = notification?.title ?? data['title']?.toString();
  final body = notification?.body ?? data['body']?.toString();
  if (title == null && body == null) return;

  const androidDetails = AndroidNotificationDetails(
    'mosaed_provider_channel',
    'Mosaed Provider Notifications',
    channelDescription: 'Notifications for Mosaed Provider app',
    importance: Importance.max,
    priority: Priority.high,
  );

  const iosDetails = DarwinNotificationDetails();

  const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await backgroundPlugin.show(
    notification?.hashCode ?? Object.hash(title, body),
    title,
    body,
    notificationDetails,
    payload: data['route']?.toString() ?? '',
  );
}
