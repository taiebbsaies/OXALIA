import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import 'notification_inbox.dart';

/// Top-level handler required by firebase_messaging for background isolates.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

/// Owns FCM permission, token registration, foreground display, and tap routing.
class PushNotificationService {
  PushNotificationService(this._apiClient, {NotificationInbox? inbox})
      : _inbox = inbox;

  final ApiClient _apiClient;
  final NotificationInbox? _inbox;

  /// Lazily assigned AFTER [Firebase.initializeApp] — never in a field
  /// initializer (that crashes with [core/no-app] before runApp).
  FirebaseMessaging? _messaging;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  void Function(String examId)? onOpenExam;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'oxalia_analysis',
    'Analysis updates',
    description: 'Notifications when an X-ray analysis finishes',
    importance: Importance.high,
  );

  bool get isReady => _ready;

  /// Initialize Firebase + listeners. Safe to call when Firebase is not
  /// configured yet — push simply stays disabled.
  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e, st) {
      debugPrint('Push disabled (Firebase init failed): $e\n$st');
      return;
    }

    _messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push permission denied');
      return;
    }

    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

    final initial = await _messaging!.getInitialMessage();
    if (initial != null) {
      await _recordMessage(initial);
      _handleMessageOpen(initial);
    }

    _ready = true;
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    await _recordMessage(message);
    await _showLocalBanner(message);
  }

  Future<void> _recordMessage(RemoteMessage message) async {
    final inbox = _inbox;
    if (inbox == null) return;

    final notification = message.notification;
    final title = notification?.title ?? 'OXALIA';
    final body = notification?.body ?? 'Analysis update';
    final examId = message.data['exam_id'];
    final status = message.data['status'];

    await inbox.addAnalysisUpdate(
      title: title,
      body: body,
      examId: examId,
      status: status,
    );
  }

  Future<void> _showLocalBanner(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'OXALIA';
    final body = notification?.body ?? 'Analysis update';
    final examId = message.data['exam_id'];

    await _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: examId,
    );
  }

  /// Register / refresh the FCM token with the backend (call after login).
  Future<void> registerToken() async {
    if (!_ready || _messaging == null) return;

    try {
      final token = await _messaging!.getToken();
      if (token == null || token.isEmpty) return;

      await _apiClient.dio.post(
        ApiEndpoints.fcmToken,
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );

      _messaging!.onTokenRefresh.listen((newToken) async {
        try {
          await _apiClient.dio.post(
            ApiEndpoints.fcmToken,
            data: {
              'token': newToken,
              'platform': Platform.isIOS ? 'ios' : 'android',
            },
          );
        } catch (e) {
          debugPrint('FCM token refresh register failed: $e');
        }
      });
    } on DioException catch (e) {
      debugPrint('FCM token register failed: $e');
    } catch (e) {
      debugPrint('FCM token register failed: $e');
    }
  }

  Future<void> unregisterCurrentToken() async {
    if (!_ready || _messaging == null) return;
    try {
      final token = await _messaging!.getToken();
      if (token == null) return;
      await _apiClient.dio.delete(
        ApiEndpoints.fcmToken,
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
    } catch (e) {
      debugPrint('FCM token unregister failed: $e');
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final examId = response.payload;
    if (examId != null && examId.isNotEmpty) {
      onOpenExam?.call(examId);
    }
  }

  void _handleMessageOpen(RemoteMessage message) {
    final examId = message.data['exam_id'];
    if (examId != null && examId.isNotEmpty) {
      onOpenExam?.call(examId);
    }
  }
}
