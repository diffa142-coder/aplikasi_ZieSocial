import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/firestore_chat_service.dart';
import '../core/firestore_notification_service.dart';
import '../core/local_storage.dart';
import '../model/message_model.dart';
import '../model/post_model.dart';
import 'login_viewmodel.dart';

class ChatViewModel extends ChangeNotifier {
  static const String _messagesKey = 'ziesocial_direct_messages';

  ChatViewModel() {
    _restoreMessages();
  }

  final List<DirectMessageModel> _messages = [];
  final Map<int, AuthorModel> _remoteUsersById = {};
  final Map<String, StreamSubscription<List<DirectMessageModel>>> _chatSubs =
      {};
  final Map<String, List<DirectMessageModel>> _remoteMessagesByChatId = {};

  StreamSubscription<List<AuthorModel>>? _usersSub;
  StreamSubscription<List<String>>? _userChatsSub;
  int? _boundUserId;
  final Set<int> _hiddenMessageIds = {};

  static String _hiddenKeyFor(int userId) => 'ziesocial_hidden_msgs_$userId';

  List<DirectMessageModel> get allMessages => List.unmodifiable(_messages);

  void _restoreMessages() {
    try {
      final raw = LocalStorage.getString(_messagesKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _messages
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map(
                    (m) => DirectMessageModel.fromJson(
                      Map<String, dynamic>.from(m),
                    ),
                  ),
            );
        }
      }
    } catch (_) {}
  }

  void _saveMessages() {
    try {
      LocalStorage.setString(
        _messagesKey,
        jsonEncode(_messages.map((m) => m.toJson()).toList()),
      );
    } catch (_) {}
  }

  /// Hubungkan stream Firestore real-time untuk pengguna aktif.
  void bindUser(int currentUserId) {
    if (currentUserId <= 0) return;
    if (_boundUserId == currentUserId && _userChatsSub != null) return;

    _unbindAll();
    _boundUserId = currentUserId;
    _restoreHiddenMessages(currentUserId);

    if (!FirestoreChatService.isReady) return;

    _usersSub = FirestoreChatService.watchUsers().listen((users) {
      for (final u in users) {
        _remoteUsersById[u.id] = u;
        LoginViewModel.saveUserProfileEntry(
          id: u.id,
          username: u.username,
          name: u.name,
          avatar: u.avatar,
        );
      }
      notifyListeners();
    });

    _userChatsSub =
        FirestoreChatService.watchUserChatIds(currentUserId).listen((chatIds) {
      final activeSet = chatIds.toSet();
      final removedIds = _chatSubs.keys
          .where((id) => !activeSet.contains(id))
          .toList();
      if (removedIds.isNotEmpty) {
        for (final id in removedIds) {
          _chatSubs.remove(id)?.cancel();
          _remoteMessagesByChatId.remove(id);
          _messages.removeWhere(
            (m) =>
                FirestoreChatService.chatIdFor(m.senderId, m.receiverId) == id,
          );
        }
        _saveMessages();
        notifyListeners();
      }
      for (final chatId in chatIds) {
        _subscribeToChatId(chatId);
      }
    });
  }

  /// Pastikan room percakapan tertentu langsung berlangganan stream real-time.
  void bindConversation(int currentUserId, int partnerId) {
    bindUser(currentUserId);
    if (!FirestoreChatService.isReady ||
        currentUserId <= 0 ||
        partnerId <= 0) {
      return;
    }
    final chatId = FirestoreChatService.chatIdFor(currentUserId, partnerId);
    _subscribeToChatId(chatId);
  }

  void _subscribeToChatId(String chatId) {
    if (_chatSubs.containsKey(chatId)) return;
    _chatSubs[chatId] =
        FirestoreChatService.watchChatMessages(chatId).listen((remoteMsgs) {
      _remoteMessagesByChatId[chatId] = remoteMsgs;
      _mergeRemoteChatMessages(chatId, remoteMsgs);
    });
  }

  void _mergeRemoteChatMessages(
    String chatId,
    List<DirectMessageModel> remoteMsgs,
  ) {
    // Hapus pesan lama untuk chatId ini yang sudah tidak ada di Firestore
    // (termasuk pesan yang ditarik oleh pengirim), lalu masukkan snapshot terbaru.
    _messages.removeWhere(
      (m) =>
          FirestoreChatService.chatIdFor(m.senderId, m.receiverId) == chatId,
    );
    _messages.addAll(remoteMsgs);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _saveMessages();
    notifyListeners();
  }

  void _unbindAll() {
    _usersSub?.cancel();
    _usersSub = null;
    _userChatsSub?.cancel();
    _userChatsSub = null;
    _hiddenMessageIds.clear();
    for (final sub in _chatSubs.values) {
      sub.cancel();
    }
    _chatSubs.clear();
    _remoteMessagesByChatId.clear();
  }

  void _restoreHiddenMessages(int userId) {
    _hiddenMessageIds.clear();
    try {
      final raw = LocalStorage.getString(_hiddenKeyFor(userId));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final id in decoded) {
            final parsed = int.tryParse(id.toString());
            if (parsed != null && parsed > 0) {
              _hiddenMessageIds.add(parsed);
            }
          }
        }
      }
    } catch (_) {}
  }

  void _saveHiddenMessages() {
    final uid = _boundUserId;
    if (uid == null || uid <= 0) return;
    try {
      LocalStorage.setString(
        _hiddenKeyFor(uid),
        jsonEncode(_hiddenMessageIds.toList()),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _unbindAll();
    super.dispose();
  }

  /// Sinkronkan dari localStorage agar pesan lokal langsung terbaca.
  void refreshFromStorage() {
    if (!FirestoreChatService.isReady) {
      _restoreMessages();
    } else if (_boundUserId != null) {
      final uid = _boundUserId!;
      _boundUserId = null;
      bindUser(uid);
    }
    notifyListeners();
  }

  AuthorModel resolveUserInfo(int userId, {AuthorModel? fallback}) {
    if (_remoteUsersById.containsKey(userId)) {
      return _remoteUsersById[userId]!;
    }
    LoginViewModel.ensureStorageLoaded();
    final saved = LoginViewModel.getSavedProfile(userId);
    if (saved != null) {
      final uname = saved['username']?.toString() ?? fallback?.username ?? '';
      final name = saved['name']?.toString() ?? fallback?.name ?? uname;
      final avatar = saved['avatar']?.toString() ?? fallback?.avatar;
      return AuthorModel(
        id: userId,
        username: uname.isNotEmpty ? uname : 'user_$userId',
        name: name.isNotEmpty ? name : 'Pengguna',
        avatar: avatar,
        isVerified: uname.toLowerCase() == 'ziesocial' ||
            uname.toLowerCase() == 'ziesocial.id',
      );
    }
    if (fallback != null) {
      return fallback;
    }
    return AuthorModel(
      id: userId,
      username: 'user_$userId',
      name: 'Pengguna $userId',
      avatar: null,
    );
  }

  List<AuthorModel> getAvailableUsers(
    int currentUserId, {
    List<PostModel> posts = const [],
    String query = '',
  }) {
    LoginViewModel.ensureStorageLoaded();
    final Map<int, AuthorModel> usersById = {};

    for (final remoteUser in _remoteUsersById.values) {
      if (remoteUser.id > 0 && remoteUser.id != currentUserId) {
        usersById[remoteUser.id] = remoteUser;
      }
    }

    for (final profileData in LoginViewModel.localProfiles.values) {
      final id = profileData['id'] is int
          ? profileData['id'] as int
          : int.tryParse(profileData['id']?.toString() ?? '0') ?? 0;
      if (id > 0 && id != currentUserId && !usersById.containsKey(id)) {
        final uname = profileData['username']?.toString() ?? '';
        final name = profileData['name']?.toString() ?? '';
        final avatar = profileData['avatar']?.toString();
        usersById[id] = AuthorModel(
          id: id,
          username: uname,
          name: name.isNotEmpty ? name : uname,
          avatar: avatar,
          isVerified: uname.toLowerCase() == 'ziesocial' ||
              uname.toLowerCase() == 'ziesocial.id',
        );
      }
    }

    for (final post in posts) {
      final author = post.author;
      if (author != null &&
          author.id > 0 &&
          author.id != currentUserId &&
          !usersById.containsKey(author.id)) {
        usersById[author.id] = resolveUserInfo(author.id, fallback: author);
      }
    }

    final q = query.trim().toLowerCase();
    final list = usersById.values.where((u) {
      if (q.isEmpty) return true;
      return u.username.toLowerCase().contains(q) ||
          u.name.toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) => a.username.compareTo(b.username));
    return list;
  }

  List<ChatConversationSummary> getConversationsFor(
    int currentUserId, {
    List<PostModel> posts = const [],
    String query = '',
  }) {
    final Map<int, List<DirectMessageModel>> grouped = {};

    for (final msg in _messages) {
      if (_hiddenMessageIds.contains(msg.id)) continue;
      if (msg.senderId == currentUserId && msg.receiverId != currentUserId) {
        grouped.putIfAbsent(msg.receiverId, () => []).add(msg);
      } else if (msg.receiverId == currentUserId &&
          msg.senderId != currentUserId) {
        grouped.putIfAbsent(msg.senderId, () => []).add(msg);
      }
    }

    final Map<int, AuthorModel> postAuthors = {};
    for (final p in posts) {
      if (p.author != null) {
        postAuthors[p.author!.id] = p.author!;
      }
    }

    final q = query.trim().toLowerCase();
    final List<ChatConversationSummary> summaries = [];

    grouped.forEach((partnerId, msgs) {
      msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final lastMsg = msgs.isNotEmpty ? msgs.last : null;
      final unread = msgs
          .where((m) => m.receiverId == currentUserId && !m.isRead)
          .length;
      final partner = resolveUserInfo(
        partnerId,
        fallback: postAuthors[partnerId],
      );

      if (q.isEmpty ||
          partner.username.toLowerCase().contains(q) ||
          partner.name.toLowerCase().contains(q) ||
          (lastMsg?.text.toLowerCase().contains(q) ?? false)) {
        summaries.add(
          ChatConversationSummary(
            partner: partner,
            lastMessage: lastMsg,
            unreadCount: unread,
          ),
        );
      }
    });

    summaries.sort((a, b) {
      final tA = a.lastMessage?.timestamp ?? '';
      final tB = b.lastMessage?.timestamp ?? '';
      return tB.compareTo(tA);
    });

    return summaries;
  }

  List<DirectMessageModel> getMessagesBetween(
    int currentUserId,
    int partnerId,
  ) {
    final list = _messages.where((m) {
      if (_hiddenMessageIds.contains(m.id)) return false;
      return (m.senderId == currentUserId && m.receiverId == partnerId) ||
          (m.senderId == partnerId && m.receiverId == currentUserId);
    }).toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  int getTotalUnreadCount(int currentUserId) {
    return _messages
        .where(
          (m) =>
              !_hiddenMessageIds.contains(m.id) &&
              m.receiverId == currentUserId &&
              !m.isRead,
        )
        .length;
  }

  void sendMessage({
    required int senderId,
    required int receiverId,
    required String text,
    String? imageUrl,
    AuthorModel? receiverInfo,
    int? replyToId,
    String? replyToSenderName,
    String? replyToText,
  }) {
    final trimmed = text.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    if (trimmed.isEmpty && !hasImage) return;

    if (receiverInfo != null) {
      final existing = LoginViewModel.getSavedProfile(receiverId);
      if (existing == null) {
        LoginViewModel.saveUserProfileEntry(
          id: receiverId,
          username: receiverInfo.username,
          name: receiverInfo.name,
          avatar: receiverInfo.avatar,
        );
      }
    }

    final msg = DirectMessageModel(
      id: DateTime.now().microsecondsSinceEpoch,
      senderId: senderId,
      receiverId: receiverId,
      text: trimmed,
      imageUrl: hasImage ? imageUrl : null,
      timestamp: DateTime.now().toIso8601String(),
      isRead: false,
      isLiked: false,
      replyToId: replyToId,
      replyToSenderName: replyToSenderName,
      replyToText: replyToText,
    );

    _messages.add(msg);
    _saveMessages();
    notifyListeners();

    bindConversation(senderId, receiverId);
    FirestoreChatService.sendMessage(msg);

    if (receiverId != senderId) {
      final partner = receiverInfo ?? resolveUserInfo(receiverId);
      final isReply = replyToId != null && replyToId > 0;
      final isMention = !isReply &&
          partner.username.isNotEmpty &&
          trimmed.toLowerCase().contains('@${partner.username.toLowerCase()}');
      final String preview = trimmed.length > 80
          ? '${trimmed.substring(0, 80)}...'
          : trimmed;
      final String notifType = isReply
          ? 'reply'
          : (isMention ? 'mention' : 'message');
      final String notifBody = isReply
          ? 'membalas pesan Anda: "${preview.isNotEmpty ? preview : 'Foto'}"'
          : isMention
              ? 'menandai Anda dalam pesan: "$preview"'
              : (preview.isNotEmpty ? preview : 'mengirim foto');

      FirestoreNotificationService.sendActivityNotification(
        recipientId: receiverId,
        actorId: senderId,
        type: notifType,
        body: notifBody,
        chatPartnerId: senderId,
      );
    }
  }

  void markConversationRead({
    required int currentUserId,
    required int partnerId,
  }) {
    final List<int> updatedIds = [];
    for (final msg in _messages) {
      if (msg.senderId == partnerId &&
          msg.receiverId == currentUserId &&
          !msg.isRead) {
        msg.isRead = true;
        updatedIds.add(msg.id);
      }
    }
    if (updatedIds.isNotEmpty) {
      _saveMessages();
      notifyListeners();
      FirestoreChatService.markMessagesRead(
        currentUserId: currentUserId,
        partnerId: partnerId,
        messageIds: updatedIds,
      );
    }
  }

  void _notifyReaction(DirectMessageModel msg, String emoji) {
    final actorId = _boundUserId ?? LoginViewModel.currentUserIdStatic;
    if (actorId == null || actorId <= 0) return;
    final recipientId = msg.senderId == actorId ? msg.receiverId : msg.senderId;
    if (recipientId <= 0 || recipientId == actorId) return;

    FirestoreNotificationService.sendActivityNotification(
      recipientId: recipientId,
      actorId: actorId,
      type: 'reaction',
      body: 'memberi reaksi $emoji pada pesan Anda',
      chatPartnerId: actorId,
    );
  }

  void toggleLikeMessage(int messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final msg = _messages[index];
      final bool willLike = msg.activeReaction != '❤️';
      msg.isLiked = willLike;
      msg.reaction = willLike ? '❤️' : null;
      _saveMessages();
      notifyListeners();
      FirestoreChatService.setMessageReaction(
        userA: msg.senderId,
        userB: msg.receiverId,
        messageId: msg.id,
        reaction: msg.reaction,
        isLiked: msg.isLiked,
      );
      if (willLike) {
        _notifyReaction(msg, '❤️');
      }
    }
  }

  void setMessageReaction(int messageId, String emoji) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final msg = _messages[index];
    final bool sameEmoji = msg.activeReaction == emoji;
    msg.reaction = sameEmoji ? null : emoji;
    msg.isLiked = !sameEmoji;
    _saveMessages();
    notifyListeners();
    FirestoreChatService.setMessageReaction(
      userA: msg.senderId,
      userB: msg.receiverId,
      messageId: msg.id,
      reaction: msg.reaction,
      isLiked: msg.isLiked,
    );
    if (!sameEmoji) {
      _notifyReaction(msg, emoji);
    }
  }

  void deleteMessage(int messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final msg = _messages[index];
    _messages.removeAt(index);
    _saveMessages();
    notifyListeners();
    FirestoreChatService.deleteMessage(
      userA: msg.senderId,
      userB: msg.receiverId,
      messageId: msg.id,
    );
  }

  void deleteMessageForMe(int messageId) {
    if (messageId <= 0) return;
    _hiddenMessageIds.add(messageId);
    _saveHiddenMessages();
    notifyListeners();
  }

  void deleteMessagesForMe(Iterable<int> messageIds) {
    bool changed = false;
    for (final id in messageIds) {
      if (id > 0 && _hiddenMessageIds.add(id)) {
        changed = true;
      }
    }
    if (changed) {
      _saveHiddenMessages();
      notifyListeners();
    }
  }

  Future<void> deleteMessagesForEveryone({
    required int currentUserId,
    required int partnerId,
    required List<int> messageIds,
  }) async {
    if (messageIds.isEmpty) return;
    final idSet = messageIds.toSet();
    _messages.removeWhere((m) => idSet.contains(m.id));
    _saveMessages();
    notifyListeners();
    await FirestoreChatService.deleteMessagesBatch(
      userA: currentUserId,
      userB: partnerId,
      messageIds: messageIds,
    );
  }

  Future<void> clearConversation({
    required int currentUserId,
    required int partnerId,
    required bool forEveryone,
  }) async {
    final relatedIds = _messages
        .where(
          (m) =>
              (m.senderId == currentUserId && m.receiverId == partnerId) ||
              (m.senderId == partnerId && m.receiverId == currentUserId),
        )
        .map((m) => m.id)
        .toList();

    if (!forEveryone) {
      deleteMessagesForMe(relatedIds);
      return;
    }

    final idSet = relatedIds.toSet();
    _messages.removeWhere((m) => idSet.contains(m.id));
    _saveMessages();
    notifyListeners();
    await FirestoreChatService.deleteConversation(
      userA: currentUserId,
      userB: partnerId,
    );
  }
}
