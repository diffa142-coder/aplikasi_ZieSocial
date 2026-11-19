import '../core/constants.dart';

class CommentModel {
  final int id;
  final int userId;
  final int postId;
  final String text;
  final String? createDate;
  final String username;
  final String name;
  final String? avatar;

  CommentModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.text,
    this.createDate,
    required this.username,
    required this.name,
    this.avatar,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      postId: json['post_id'] is int
          ? json['post_id']
          : int.tryParse(json['post_id']?.toString() ?? '0') ?? 0,
      text: json['text']?.toString() ?? '',
      createDate: json['create_date']?.toString(),
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Pengguna',
      avatar: json['avatar']?.toString(),
    );
  }

  String? get fullAvatarUrl => ApiConstants.getImageUrl(avatar);
}
