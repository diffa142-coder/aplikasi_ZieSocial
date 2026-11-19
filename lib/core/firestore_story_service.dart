import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../model/story_model.dart';

class FirestoreStoryService {
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

  static Stream<List<StoryModel>> watchStories() {
    if (!_isReady) {
      return const Stream.empty();
    }

    return _db
        .collection('stories')
        .orderBy('create_date', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StoryModel.fromJson(doc.data()))
              .where((s) => s.id > 0 && s.mediaUrl.isNotEmpty && !s.isExpired)
              .toList(),
        );
  }

  static Future<void> addStory(StoryModel story) async {
    if (!_isReady || story.id <= 0 || story.author.id <= 0) return;

    final safeMedia = story.mediaUrl.trim();
    if (safeMedia.isEmpty || safeMedia.length > 950000) {
      debugPrint('Story media exceeds Firestore limit (${safeMedia.length} chars)');
      return;
    }

    final safeCaption = _boundNullableLen(story.caption?.trim(), 300);
    final safeAvatar = _boundNullableLen(story.author.avatar, 500000);
    final safeName = story.author.name.trim().isNotEmpty
        ? _boundLen(story.author.name.trim(), 100)
        : _boundLen(story.author.username, 100);
    final safeUsername = story.author.username.trim().isNotEmpty
        ? _boundLen(story.author.username.trim(), 50)
        : 'user_${story.author.id}';

    try {
      await _db.collection('stories').doc(story.id.toString()).set({
        'id': story.id,
        'author_id': story.author.id,
        'author_username': safeUsername,
        'author_name': safeName,
        'author_avatar': safeAvatar,
        'author_verified': story.author.isVerified,
        'media_url': safeMedia,
        'caption': ?safeCaption,
        'create_date': story.createDate,
        'viewed_by': story.viewedByUserIds.toList(),
      });
    } catch (e) {
      debugPrint('Firestore addStory error: $e');
    }
  }

  static Future<void> markStoryViewed(int storyId, int userId) async {
    if (!_isReady || storyId <= 0 || userId <= 0) return;
    try {
      await _db.collection('stories').doc(storyId.toString()).update({
        'viewed_by': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Firestore markStoryViewed error: $e');
    }
  }

  static Future<void> deleteStory(int storyId) async {
    if (!_isReady || storyId <= 0) return;
    try {
      await _db.collection('stories').doc(storyId.toString()).delete();
    } catch (e) {
      debugPrint('Firestore deleteStory error: $e');
    }
  }
}
