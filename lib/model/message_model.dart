import 'post_model.dart';

class DirectMessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String text;
  final String? imageUrl;
  final String timestamp;
  bool isRead;
  bool isLiked;
  String? reaction;
  final int? replyToId;
  final String? replyToSenderName;
  final String? replyToText;

  DirectMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    this.isRead = false,
    this.isLiked = false,
    this.reaction,
    this.replyToId,
    this.replyToSenderName,
    this.replyToText,
  });

  String? get activeReaction {
    if (reaction != null && reaction!.isNotEmpty) return reaction;
    if (isLiked) return '❤️';
    return null;
  }

  factory DirectMessageModel.fromJson(Map<String, dynamic> json) {
    final parsedReplyId = json['reply_to_id'] is int
        ? json['reply_to_id'] as int
        : int.tryParse(json['reply_to_id']?.toString() ?? '');

    return DirectMessageModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      senderId: json['sender_id'] is int
          ? json['sender_id'] as int
          : int.tryParse(json['sender_id']?.toString() ?? '0') ?? 0,
      receiverId: json['receiver_id'] is int
          ? json['receiver_id'] as int
          : int.tryParse(json['receiver_id']?.toString() ?? '0') ?? 0,
      text: json['text']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      timestamp:
          json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      isRead: json['is_read'] == true,
      isLiked: json['is_liked'] == true,
      reaction: json['reaction']?.toString(),
      replyToId: (parsedReplyId != null && parsedReplyId > 0)
          ? parsedReplyId
          : null,
      replyToSenderName: json['reply_to_sender_name']?.toString(),
      replyToText: json['reply_to_text']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'text': text,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'image_url': imageUrl,
      'timestamp': timestamp,
      'is_read': isRead,
      'is_liked': isLiked,
      if (reaction != null && reaction!.isNotEmpty) 'reaction': reaction,
      if (replyToId != null && replyToId! > 0) 'reply_to_id': replyToId,
      if (replyToSenderName != null && replyToSenderName!.isNotEmpty)
        'reply_to_sender_name': replyToSenderName,
      if (replyToText != null && replyToText!.isNotEmpty)
        'reply_to_text': replyToText,
    };
  }
}

class ChatConversationSummary {
  final AuthorModel partner;
  final DirectMessageModel? lastMessage;
  final int unreadCount;

  ChatConversationSummary({
    required this.partner,
    this.lastMessage,
    this.unreadCount = 0,
  });
}
