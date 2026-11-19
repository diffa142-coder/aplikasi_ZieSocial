import '../core/constants.dart';
import 'post_model.dart';

class StoryModel {
  final int id;
  AuthorModel author;
  final String mediaUrl;
  final String? caption;
  final String createDate;
  final Set<int> viewedByUserIds;

  StoryModel({
    required this.id,
    required this.author,
    required this.mediaUrl,
    this.caption,
    required this.createDate,
    Set<int>? viewedByUserIds,
  }) : viewedByUserIds = viewedByUserIds ?? <int>{};

  bool isViewedBy(int userId) => viewedByUserIds.contains(userId);

  bool get isExpired {
    try {
      final created = DateTime.parse(createDate);
      return DateTime.now().difference(created).inHours >= 24;
    } catch (_) {
      return false;
    }
  }

  String? get fullMediaUrl => ApiConstants.getImageUrl(mediaUrl);

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final Set<int> viewedSet = <int>{};
    if (json['viewed_by'] is List) {
      for (final item in json['viewed_by'] as List) {
        final parsed = int.tryParse(item.toString());
        if (parsed != null && parsed > 0) {
          viewedSet.add(parsed);
        }
      }
    }

    AuthorModel resolvedAuthor;
    if (json['author'] is Map<String, dynamic>) {
      resolvedAuthor = AuthorModel.fromJson(json['author'] as Map<String, dynamic>);
    } else if (json['author'] is Map) {
      resolvedAuthor = AuthorModel.fromJson(Map<String, dynamic>.from(json['author'] as Map));
    } else {
      final uname = (json['author_username'] ?? json['username'] ?? 'ziesocial')
          .toString();
      resolvedAuthor = AuthorModel(
        id: int.tryParse(json['author_id']?.toString() ?? '1') ?? 1,
        username: uname,
        name: (json['author_name'] ?? 'ZieSocial Official').toString(),
        avatar: (json['author_avatar'] ?? json['avatar'])?.toString(),
        isVerified: json['author_verified'] == true ||
            uname.toLowerCase() == 'ziesocial' ||
            uname.toLowerCase() == 'ziesocial.id',
      );
    }

    return StoryModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? DateTime.now().millisecondsSinceEpoch,
      author: resolvedAuthor,
      mediaUrl: json['media_url']?.toString() ?? '',
      caption: json['caption']?.toString(),
      createDate: json['create_date']?.toString() ?? DateTime.now().toIso8601String(),
      viewedByUserIds: viewedSet,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'media_url': mediaUrl,
      'caption': caption,
      'create_date': createDate,
      'viewed_by': viewedByUserIds.toList(),
    };
  }
}

