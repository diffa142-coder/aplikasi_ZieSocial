import '../core/constants.dart';
import 'post_model.dart';

class UserProfileModel {
  final int id;
  final String username;
  String name;
  final String? email;
  String? avatar;
  String? bio;
  int postsCount;
  int followersCount;
  int followingCount;
  bool isFollowing;
  final List<PostModel> posts;

  UserProfileModel({
    required this.id,
    required this.username,
    required this.name,
    this.email,
    this.avatar,
    this.bio,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.posts = const [],
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final userJson = (json['user'] is Map<String, dynamic>)
        ? json['user'] as Map<String, dynamic>
        : json;

    final List<PostModel> postsList = [];
    if (json['posts'] is List) {
      for (final p in json['posts']) {
        if (p is Map<String, dynamic>) {
          postsList.add(PostModel.fromJson(p));
        }
      }
    }

    return UserProfileModel(
      id: userJson['id'] is int
          ? userJson['id']
          : int.tryParse(userJson['id']?.toString() ?? '0') ?? 0,
      username: userJson['username']?.toString() ?? '',
      name: userJson['name']?.toString() ?? '',
      email: userJson['email']?.toString(),
      avatar: userJson['avatar']?.toString(),
      bio: userJson['bio']?.toString(),
      postsCount: json['posts_count'] is int
          ? json['posts_count']
          : int.tryParse(json['posts_count']?.toString() ?? '0') ??
              postsList.length,
      followersCount: json['followers_count'] is int
          ? json['followers_count']
          : int.tryParse(json['followers_count']?.toString() ?? '0') ?? 0,
      followingCount: json['following_count'] is int
          ? json['following_count']
          : int.tryParse(json['following_count']?.toString() ?? '0') ?? 0,
      isFollowing: json['is_following'] == true ||
          json['is_following'] == 1 ||
          json['is_following'] == '1',
      posts: postsList,
    );
  }

  String? get fullAvatarUrl => ApiConstants.getImageUrl(avatar);
}
