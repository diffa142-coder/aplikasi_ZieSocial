import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../model/message_model.dart';
import '../model/post_model.dart';

class FirestoreChatService {
  static bool _initialized = false;

  static bool get isReady => _initialized;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
        _initialized = Firebase.apps.isNotEmpty;
      }
    } catch (e) {
      debugPrint('Firebase init skipped/failed: $e');
      _initialized = false;
    }
  }

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String chatIdFor(int userA, int userB) {
    return userA < userB ? '${userA}_$userB' : '${userB}_$userA';
  }

  static String? _boundLen(String? value, int maxLen) {
    if (value == null || value.isEmpty) return null;
    if (value.length <= maxLen) return value;
    return null;
  }

  static Future<void> syncUser({
    required int id,
    required String username,
    required String name,
    String? avatar,
    String? bio,
  }) async {
    if (!_initialized || id <= 0) return;
    final cleanUsername = username.trim();
    final cleanName = name.trim().isNotEmpty ? name.trim() : cleanUsername;
    if (cleanUsername.isEmpty) return;

    final isVerified = cleanUsername.toLowerCase() == 'ziesocial' ||
        cleanUsername.toLowerCase() == 'ziesocial.id';

    try {
      await _db.collection('users').doc(id.toString()).set({
        'id': id,
        'username': cleanUsername.length > 50
            ? cleanUsername.substring(0, 50)
            : cleanUsername,
        'name': cleanName.length > 100
            ? cleanName.substring(0, 100)
            : cleanName,
        'avatar': _boundLen(avatar, 450000),
        'bio': _boundLen(bio, 500),
        'is_verified': isVerified,
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore syncUser error: $e');
    }
  }

  static Stream<List<AuthorModel>> watchUsers() {
    if (!_initialized) {
      return const Stream.empty();
    }
    return _db.collection('users').snapshots().map((snapshot) {
      final list = <AuthorModel>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final id = data['id'] is int
            ? data['id'] as int
            : int.tryParse(doc.id) ?? 0;
        if (id > 0) {
          list.add(
            AuthorModel(
              id: id,
              username: data['username']?.toString() ?? '',
              name: data['name']?.toString() ?? '',
              avatar: data['avatar']?.toString(),
              isVerified: data['is_verified'] == true,
            ),
          );
        }
      }
      return list;
    });
  }

  static Stream<List<String>> watchUserChatIds(int currentUserId) {
    if (!_initialized || currentUserId <= 0) {
      return const Stream.empty();
    }
    return _db
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
  }

  static Stream<List<DirectMessageModel>> watchChatMessages(String chatId) {
    if (!_initialized || chatId.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('id')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DirectMessageModel.fromJson(doc.data()))
          .toList();
    });
  }

  static Future<void> sendMessage(DirectMessageModel msg) async {
    if (!_initialized) return;
    final chatId = chatIdFor(msg.senderId, msg.receiverId);
    final participants = msg.senderId < msg.receiverId
        ? [msg.senderId, msg.receiverId]
        : [msg.receiverId, msg.senderId];
    final safeText =
        msg.text.length > 2000 ? msg.text.substring(0, 2000) : msg.text;
    final safeImage = _boundLen(msg.imageUrl, 900000);
    final safeReplySender = _boundLen(msg.replyToSenderName, 100);
    final safeReplyText = _boundLen(msg.replyToText, 300);

    try {
      final chatRef = _db.collection('chats').doc(chatId);
      await chatRef.set({
        'participants': participants,
        'last_message': safeText,
        'last_image_url': safeImage,
        'last_sender_id': msg.senderId,
        'last_timestamp': msg.timestamp,
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      await chatRef.collection('messages').doc(msg.id.toString()).set({
        'id': msg.id,
        'sender_id': msg.senderId,
        'receiver_id': msg.receiverId,
        'text': safeText,
        'image_url': safeImage,
        'timestamp': msg.timestamp,
        'is_read': msg.isRead,
        'is_liked': msg.isLiked,
        if (msg.reaction != null && msg.reaction!.isNotEmpty)
          'reaction': _boundLen(msg.reaction, 16),
        if (msg.replyToId != null && msg.replyToId! > 0)
          'reply_to_id': msg.replyToId,
        'reply_to_sender_name': ?safeReplySender,
        'reply_to_text': ?safeReplyText,
      });
    } catch (e) {
      debugPrint('Firestore sendMessage error: $e');
    }
  }

  static Future<void> markMessagesRead({
    required int currentUserId,
    required int partnerId,
    required List<int> messageIds,
  }) async {
    if (!_initialized || messageIds.isEmpty) return;
    final chatId = chatIdFor(currentUserId, partnerId);
    try {
      final batch = _db.batch();
      final messagesRef =
          _db.collection('chats').doc(chatId).collection('messages');
      for (final msgId in messageIds) {
        batch.update(messagesRef.doc(msgId.toString()), {'is_read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore markMessagesRead error: $e');
    }
  }

  static Future<void> setMessageLiked({
    required int userA,
    required int userB,
    required int messageId,
    required bool isLiked,
  }) async {
    return setMessageReaction(
      userA: userA,
      userB: userB,
      messageId: messageId,
      reaction: isLiked ? '❤️' : null,
      isLiked: isLiked,
    );
  }

  static Future<void> setMessageReaction({
    required int userA,
    required int userB,
    required int messageId,
    required String? reaction,
    bool? isLiked,
  }) async {
    if (!_initialized) return;
    final chatId = chatIdFor(userA, userB);
    final bool hasReaction = reaction != null && reaction.isNotEmpty;
    try {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId.toString())
          .update({
        'is_liked': isLiked ?? hasReaction,
        'reaction': hasReaction ? _boundLen(reaction, 16) : null,
      });
    } catch (e) {
      debugPrint('Firestore setMessageReaction error: $e');
    }
  }

  static Future<void> _syncLastMessageAfterDelete(String chatId) async {
    try {
      final chatRef = _db.collection('chats').doc(chatId);
      final latestSnap = await chatRef
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (latestSnap.docs.isEmpty) {
        await chatRef.update({
          'last_message': '',
          'last_image_url': null,
          'last_timestamp': '',
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        final data = latestSnap.docs.first.data();
        final text = data['text']?.toString() ?? '';
        final imageUrl = _boundLen(data['image_url']?.toString(), 1000000);
        final safeLastMsg = text.isNotEmpty
            ? (_boundLen(text, 2000) ?? text.substring(0, 2000))
            : (imageUrl != null && imageUrl.isNotEmpty ? '📷 Foto' : '');
        await chatRef.update({
          'last_message': safeLastMsg,
          'last_image_url': imageUrl,
          'last_sender_id': data['sender_id'],
          'last_timestamp': _boundLen(data['timestamp']?.toString(), 64) ?? '',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Firestore _syncLastMessageAfterDelete error: $e');
    }
  }

  static Future<void> deleteMessage({
    required int userA,
    required int userB,
    required int messageId,
  }) async {
    if (!_initialized) return;
    final chatId = chatIdFor(userA, userB);
    try {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId.toString())
          .delete();
      await _syncLastMessageAfterDelete(chatId);
    } catch (e) {
      debugPrint('Firestore deleteMessage error: $e');
    }
  }

  static Future<void> deleteMessagesBatch({
    required int userA,
    required int userB,
    required List<int> messageIds,
  }) async {
    if (!_initialized || messageIds.isEmpty) return;
    final chatId = chatIdFor(userA, userB);
    try {
      final messagesRef =
          _db.collection('chats').doc(chatId).collection('messages');
      for (int i = 0; i < messageIds.length; i += 400) {
        final chunk = messageIds.skip(i).take(400);
        final batch = _db.batch();
        for (final msgId in chunk) {
          batch.delete(messagesRef.doc(msgId.toString()));
        }
        await batch.commit();
      }
      await _syncLastMessageAfterDelete(chatId);
    } catch (e) {
      debugPrint('Firestore deleteMessagesBatch error: $e');
    }
  }

  static Future<void> deleteConversation({
    required int userA,
    required int userB,
  }) async {
    if (!_initialized) return;
    final chatId = chatIdFor(userA, userB);
    try {
      final chatRef = _db.collection('chats').doc(chatId);
      final snap = await chatRef.collection('messages').limit(500).get();
      if (snap.docs.isNotEmpty) {
        for (int i = 0; i < snap.docs.length; i += 400) {
          final batch = _db.batch();
          for (final doc in snap.docs.skip(i).take(400)) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      }
      await chatRef.delete();
    } catch (e) {
      debugPrint('Firestore deleteConversation error: $e');
    }
  }
}

