import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../model/notification_model.dart';
import '../viewmodel/login_viewmodel.dart';
import 'push_notification_service.dart';

class FirestoreNotificationService {
  static const Set<String> _validTypes = {
    'like',
    'comment',
    'follow',
    'message',
    'reply',
    'mention',
    'reaction',
  };

  static bool get _isReady => Firebase.apps.isNotEmpty;

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String _boundLen(String value, int maxLen) {
    if (value.length <= maxLen) return value;
    return value.substring(0, maxLen);
  }

  static String? _boundNullableLen(String? value, int maxLen) {
    if (value == null || value.isEmpty) return null;
    return _boundLen(value, maxLen);
  }

  static CollectionReference<Map<String, dynamic>> _notificationsRef(
    int userId,
  ) {
    return _db
        .collection('users')
        .doc(userId.toString())
        .collection('notifications');
  }

  static Stream<List<AppNotificationModel>> watchNotifications(int userId) {
    if (!_isReady || userId <= 0) {
      return const Stream.empty();
    }

    return _notificationsRef(userId)
        .orderBy('created_at', descending: true)
        .limit(60)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotificationModel.fromJson(doc.data()))
              .where((item) => item.id > 0)
              .toList(),
        );
  }

  static Future<void> sendActivityNotification({
    required int recipientId,
    required int actorId,
    String? actorUsername,
    String? actorName,
    String? actorAvatar,
    required String type,
    required String body,
    int? postId,
    int? chatPartnerId,
  }) async {
    if (!_isReady ||
        recipientId <= 0 ||
        actorId <= 0 ||
        recipientId == actorId) {
      return;
    }

    final savedProfile = LoginViewModel.getSavedProfile(actorId);
    final isCurrentStaticActor = LoginViewModel.currentUserIdStatic == actorId;

    final resolvedUsername = (actorUsername != null && actorUsername.isNotEmpty)
        ? actorUsername
        : (isCurrentStaticActor &&
                  (LoginViewModel.currentUsername ?? '').isNotEmpty)
              ? LoginViewModel.currentUsername!
              : (savedProfile?['username']?.toString().isNotEmpty == true
                    ? savedProfile!['username'].toString()
                    : 'user_$actorId');

    final resolvedName = (actorName != null && actorName.isNotEmpty)
        ? actorName
        : (isCurrentStaticActor &&
                  (LoginViewModel.currentUserName ?? '').isNotEmpty)
              ? LoginViewModel.currentUserName!
              : (savedProfile?['name']?.toString().isNotEmpty == true
                    ? savedProfile!['name'].toString()
                    : resolvedUsername);

    final resolvedAvatar = actorAvatar ??
        (isCurrentStaticActor
            ? LoginViewModel.currentUserAvatar
            : savedProfile?['avatar']?.toString());

    final safeType = _validTypes.contains(type) ? type : 'message';
    final safeBody = body.trim().isEmpty ? 'Aktivitas baru' : body.trim();
    final safeId = DateTime.now().microsecondsSinceEpoch;
    final safeCreatedAt = DateTime.now().toIso8601String();

    final payload = <String, dynamic>{
      'id': safeId,
      'recipient_id': recipientId,
      'actor_id': actorId,
      'actor_username': _boundLen(resolvedUsername, 50),
      'actor_name': _boundLen(resolvedName, 100),
      'actor_avatar': _boundNullableLen(resolvedAvatar, 500000),
      'type': safeType,
      'body': _boundLen(safeBody, 300),
      if (postId != null && postId > 0) 'post_id': postId,
      if (chatPartnerId != null && chatPartnerId > 0)
        'chat_partner_id': chatPartnerId,
      'created_at': safeCreatedAt,
      'is_read': false,
    };

    try {
      await _notificationsRef(recipientId)
          .doc(safeId.toString())
          .set(payload);

      // Kirim juga trigger FCM push agar tetap masuk saat aplikasi ditutup/background
      PushNotificationService.triggerRemotePush(
        recipientId: recipientId,
        title: '${_boundLen(resolvedName, 100)} (@${_boundLen(resolvedUsername, 50)})',
        body: _boundLen(safeBody, 300),
        type: safeType,
        actorId: actorId,
        postId: postId,
        chatPartnerId: chatPartnerId,
      );
    } catch (e) {
      debugPrint('Firestore sendActivityNotification error: $e');
    }
  }

  static Future<void> markAsRead(int userId, int notificationId) async {
    if (!_isReady || userId <= 0 || notificationId <= 0) return;
    try {
      await _notificationsRef(userId)
          .doc(notificationId.toString())
          .update({'is_read': true});
    } catch (e) {
      debugPrint('Firestore markAsRead error: $e');
    }
  }

  static Future<void> markAllAsRead(
    int userId,
    List<int> notificationIds,
  ) async {
    if (!_isReady || userId <= 0 || notificationIds.isEmpty) return;
    try {
      final batch = _db.batch();
      final col = _notificationsRef(userId);
      for (final id in notificationIds) {
        if (id > 0) {
          batch.update(col.doc(id.toString()), {'is_read': true});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore markAllAsRead error: $e');
    }
  }

  static Future<void> deleteNotification(int userId, int notificationId) async {
    if (!_isReady || userId <= 0 || notificationId <= 0) return;
    try {
      await _notificationsRef(userId)
          .doc(notificationId.toString())
          .delete();
    } catch (e) {
      debugPrint('Firestore deleteNotification error: $e');
    }
  }
}
