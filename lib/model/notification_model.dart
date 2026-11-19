class AppNotificationModel {
  final int id;
  final int recipientId;
  final int actorId;
  final String actorUsername;
  final String actorName;
  final String? actorAvatar;
  final String type; // like, comment, follow, message, reply, mention, reaction
  final String body;
  final int? postId;
  final int? chatPartnerId;
  final String createdAt;
  bool isRead;

  AppNotificationModel({
    required this.id,
    required this.recipientId,
    required this.actorId,
    required this.actorUsername,
    required this.actorName,
    this.actorAvatar,
    required this.type,
    required this.body,
    this.postId,
    this.chatPartnerId,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      final parsed = parseInt(value);
      return parsed > 0 ? parsed : null;
    }

    return AppNotificationModel(
      id: parseInt(json['id']),
      recipientId: parseInt(json['recipient_id']),
      actorId: parseInt(json['actor_id']),
      actorUsername: json['actor_username']?.toString() ?? 'pengguna',
      actorName: json['actor_name']?.toString() ?? 'Pengguna',
      actorAvatar: json['actor_avatar']?.toString(),
      type: json['type']?.toString() ?? 'message',
      body: json['body']?.toString() ?? '',
      postId: parseNullableInt(json['post_id']),
      chatPartnerId: parseNullableInt(json['chat_partner_id']),
      createdAt: json['created_at']?.toString() ??
          DateTime.now().toIso8601String(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_id': recipientId,
      'actor_id': actorId,
      'actor_username': actorUsername,
      'actor_name': actorName,
      'actor_avatar': actorAvatar,
      'type': type,
      'body': body,
      'post_id': ?postId,
      'chat_partner_id': ?chatPartnerId,
      'created_at': createdAt,
      'is_read': isRead,
    };
  }
}
