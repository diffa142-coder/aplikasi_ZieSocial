import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';

const String _kHighChannelId = 'ziesocial_high_channel';
const String _kHighChannelName = 'Notifikasi ZieSocial';
const String _kHighChannelDesc =
    'Notifikasi real-time untuk pesan, tag, like, komentar, dan pengikut.';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}

  // Jika pesan FCM hanya membawa data (tanpa block notification sistem),
  // tampilkan notifikasi lokal agar tetap muncul di status bar Android.
  if (message.notification == null && message.data.isNotEmpty) {
    final title = message.data['title']?.toString() ?? 'ZieSocial';
    final body = message.data['body']?.toString() ?? 'Ada aktivitas baru';
    await PushNotificationService.showRawBackgroundNotification(
      id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      title: title,
      body: body,
    );
  }
}

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static StreamSubscription<String>? _tokenRefreshSub;
  static int? _activeUserId;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    _kHighChannelId,
    _kHighChannelName,
    channelDescription: _kHighChannelDesc,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
  );

  static const NotificationDetails _notificationDetails =
      NotificationDetails(android: _androidDetails);

  static Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(initSettings);

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _kHighChannelId,
          _kHighChannelName,
          description: _kHighChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();

      if (Firebase.apps.isNotEmpty) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
    } catch (e) {
      debugPrint('PushNotificationService init error: $e');
    }
  }

  static Future<void> showRawBackgroundNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(initSettings);
      await _localNotifications.show(
        id & 0x7FFFFFFF,
        title,
        body,
        _notificationDetails,
      );
    } catch (e) {
      debugPrint('Background local notification error: $e');
    }
  }

  static Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) {
      await init();
    }
    try {
      await _localNotifications.show(
        id & 0x7FFFFFFF,
        title,
        body,
        _notificationDetails,
      );
    } catch (e) {
      debugPrint('showSystemNotification error: $e');
    }
  }

  static Future<void> syncDeviceToken(int userId) async {
    if (kIsWeb || userId <= 0 || Firebase.apps.isEmpty) return;
    _activeUserId = userId;

    try {
      _tokenRefreshSub ??= FirebaseMessaging.instance.onRegistered.listen((
        newToken,
      ) {
        final uid = _activeUserId;
        if (uid != null && uid > 0 && newToken.isNotEmpty) {
          _persistToken(uid, newToken);
        }
      });

      await FirebaseMessaging.instance.register();
    } catch (e) {
      debugPrint('syncDeviceToken error: $e');
    }
  }

  static Future<void> _persistToken(int userId, String token) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId.toString());
      final snap = await docRef.get();
      if (snap.exists) {
        await docRef.update({
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Firestore persist fcm_token error: $e');
    }

    try {
      await http
          .post(
            Uri.parse(ApiConstants.registerFcmToken),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({
              'user_id': userId,
              'fcm_token': token,
            }),
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
  }

  static Future<void> triggerRemotePush({
    required int recipientId,
    required String title,
    required String body,
    required String type,
    int? actorId,
    int? postId,
    int? chatPartnerId,
  }) async {
    if (recipientId <= 0) return;

    String? recipientToken;
    try {
      if (Firebase.apps.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(recipientId.toString())
            .get();
        recipientToken = doc.data()?['fcm_token']?.toString();
      }
    } catch (_) {}

    final safeToken = (recipientToken != null && recipientToken.isNotEmpty)
        ? recipientToken
        : null;

    try {
      await http
          .post(
            Uri.parse(ApiConstants.pushNotification),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({
              'recipient_id': recipientId,
              'fcm_token': ?safeToken,
              'title': title,
              'body': body,
              'type': type,
              'actor_id': ?actorId,
              'post_id': ?postId,
              'chat_partner_id': ?chatPartnerId,
            }),
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
  }
}
