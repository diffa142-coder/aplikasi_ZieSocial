import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/firestore_notification_service.dart';
import '../core/local_storage.dart';
import '../core/push_notification_service.dart';
import '../model/notification_model.dart';

class NotificationViewModel extends ChangeNotifier {
  static String _storageKeyFor(int userId) => 'ziesocial_notifications_$userId';

  final List<AppNotificationModel> _notifications = [];
  final Set<int> _knownIds = {};

  StreamSubscription<List<AppNotificationModel>>? _sub;
  Timer? _bannerTimer;
  int? _boundUserId;
  bool _initialSnapshotLoaded = false;
  AppNotificationModel? _activeBanner;

  List<AppNotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  AppNotificationModel? get activeBanner => _activeBanner;

  void bindUser(int userId) {
    if (userId <= 0) return;
    if (_boundUserId == userId && _sub != null) return;

    _sub?.cancel();
    _bannerTimer?.cancel();
    _boundUserId = userId;
    _initialSnapshotLoaded = false;
    _activeBanner = null;
    _knownIds.clear();
    _restoreFromStorage(userId);
    PushNotificationService.syncDeviceToken(userId);

    _sub = FirestoreNotificationService.watchNotifications(userId).listen(
      (remoteItems) {
        if (_boundUserId != userId) return;

        AppNotificationModel? newestArrival;
        if (_initialSnapshotLoaded) {
          for (final item in remoteItems) {
            if (!item.isRead && !_knownIds.contains(item.id)) {
              newestArrival ??= item;
            }
          }
        }

        _notifications
          ..clear()
          ..addAll(remoteItems);
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        for (final item in _notifications) {
          _knownIds.add(item.id);
        }
        _initialSnapshotLoaded = true;
        _saveToStorage(userId);

        if (newestArrival != null) {
          PushNotificationService.showSystemNotification(
            id: newestArrival.id,
            title: '${newestArrival.actorName} (@${newestArrival.actorUsername})',
            body: newestArrival.body,
          );
          _showBanner(newestArrival);
        } else {
          notifyListeners();
        }
      },
      onError: (e) {
        debugPrint('NotificationViewModel stream error: $e');
      },
    );
  }

  void _showBanner(AppNotificationModel item) {
    _bannerTimer?.cancel();
    _activeBanner = item;
    notifyListeners();
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (_activeBanner?.id == item.id) {
        _activeBanner = null;
        notifyListeners();
      }
    });
  }

  void dismissBanner() {
    _bannerTimer?.cancel();
    if (_activeBanner != null) {
      _activeBanner = null;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final userId = _boundUserId;
    if (userId == null || notificationId <= 0) return;

    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx].isRead = true;
      _saveToStorage(userId);
      notifyListeners();
    }

    await FirestoreNotificationService.markAsRead(userId, notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _boundUserId;
    if (userId == null) return;

    final unreadIds = <int>[];
    for (final n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        unreadIds.add(n.id);
      }
    }
    if (unreadIds.isEmpty) return;

    _saveToStorage(userId);
    notifyListeners();
    await FirestoreNotificationService.markAllAsRead(userId, unreadIds);
  }

  Future<void> deleteNotification(int notificationId) async {
    final userId = _boundUserId;
    if (userId == null || notificationId <= 0) return;

    _notifications.removeWhere((n) => n.id == notificationId);
    if (_activeBanner?.id == notificationId) {
      _activeBanner = null;
    }
    _saveToStorage(userId);
    notifyListeners();
    await FirestoreNotificationService.deleteNotification(userId, notificationId);
  }

  void clear() {
    _sub?.cancel();
    _sub = null;
    _bannerTimer?.cancel();
    _boundUserId = null;
    _initialSnapshotLoaded = false;
    _activeBanner = null;
    _knownIds.clear();
    _notifications.clear();
    notifyListeners();
  }

  void _restoreFromStorage(int userId) {
    _notifications.clear();
    try {
      final raw = LocalStorage.getString(_storageKeyFor(userId));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded.whereType<Map>()) {
            final parsed = AppNotificationModel.fromJson(
              Map<String, dynamic>.from(item),
            );
            if (parsed.id > 0) {
              _notifications.add(parsed);
              _knownIds.add(parsed.id);
            }
          }
          _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  void _saveToStorage(int userId) {
    try {
      LocalStorage.setString(
        _storageKeyFor(userId),
        jsonEncode(_notifications.map((n) => n.toJson()).toList()),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }
}
