import '../core/constants.dart';

class AuthorModel {
  final int id;
  final String username;
  String name;
  String? avatar;
  final bool isVerified;

  AuthorModel({
    required this.id,
    required this.username,
    required this.name,
    this.avatar,
    this.isVerified = false,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    final uname = json['username']?.toString() ?? '';
    final bool verified = json['is_verified'] == true ||
        uname.toLowerCase() == 'ziesocial' ||
        uname.toLowerCase() == 'ziesocial.id';

    return AuthorModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: uname,
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      isVerified: verified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'avatar': avatar,
      'is_verified': isVerified,
    };
  }

  String? get fullAvatarUrl {
    if (avatar == null || avatar!.isEmpty || avatar!.contains('zie_avatar')) {
      return null;
    }
    return ApiConstants.getImageUrl(avatar);
  }
}

class PostModel {
  final int id;
  String caption;
  final String? image;
  final String? createDate;
  final String? updatedDate;
  AuthorModel? author;
  int likeCount;
  int commentCount;
  bool isLiked;
  final Set<int> likedByUserIds;

  PostModel({
    required this.id,
    required this.caption,
    this.image,
    this.createDate,
    this.updatedDate,
    this.author,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    Set<int>? likedByUserIds,
  }) : likedByUserIds = likedByUserIds ?? <int>{};

  bool isLikedBy(int userId) => likedByUserIds.contains(userId);

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final Set<int> likedSet = <int>{};
    if (json['liked_by'] is List) {
      for (final item in json['liked_by'] as List) {
        final parsed = int.tryParse(item.toString());
        if (parsed != null && parsed > 0) {
          likedSet.add(parsed);
        }
      }
    } else if (json['is_liked'] == true ||
        json['is_liked'] == 1 ||
        json['is_liked'] == '1') {
      likedSet.add(1);
    }

    final rawLikeCount = json['like_count'] is int
        ? json['like_count']
        : int.tryParse(json['like_count']?.toString() ?? '0') ?? 0;

    return PostModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      caption: json['caption']?.toString() ?? '',
      image: json['image']?.toString(),
      createDate: json['create_date']?.toString(),
      updatedDate: json['updated_date']?.toString(),
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? AuthorModel.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      likeCount: rawLikeCount > likedSet.length ? rawLikeCount : likedSet.length,
      commentCount: json['comment_count'] is int
          ? json['comment_count']
          : int.tryParse(json['comment_count']?.toString() ?? '0') ?? 0,
      isLiked: likedSet.isNotEmpty,
      likedByUserIds: likedSet,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caption': caption,
      'image': image,
      'create_date': createDate,
      'updated_date': updatedDate,
      'author': author?.toJson(),
      'like_count': likeCount,
      'comment_count': commentCount,
      'is_liked': isLiked,
      'liked_by': likedByUserIds.toList(),
    };
  }

  String? get fullImageUrl => ApiConstants.getImageUrl(image);

  static List<PostModel> fromDynamicList(dynamic data) {
    final List<PostModel> result = [];

    if (data is List) {
      if (data.isNotEmpty &&
          data.first is Map &&
          (data.first as Map).containsKey('data')) {
        // Handle format: [{"data": [...]}]
        for (final item in data) {
          if (item is Map && item['data'] is List) {
            for (final postJson in item['data'] as List) {
              if (postJson is Map<String, dynamic>) {
                result.add(PostModel.fromJson(postJson));
              }
            }
          }
        }
      } else {
        // Handle format: [{id: 1, ...}, ...]
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            result.add(PostModel.fromJson(item));
          }
        }
      }
    } else if (data is Map && data.containsKey('data') && data['data'] is List) {
      // Handle format: {"data": [...]}
      for (final item in data['data'] as List) {
        if (item is Map<String, dynamic>) {
          result.add(PostModel.fromJson(item));
        }
      }
    }

    return result;
  }
}
