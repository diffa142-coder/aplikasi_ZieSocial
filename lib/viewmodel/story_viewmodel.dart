import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/firestore_story_service.dart';
import '../core/local_storage.dart';
import '../model/post_model.dart';
import '../model/story_model.dart';
import 'login_viewmodel.dart';

class StoryViewModel extends ChangeNotifier {
  static const String _storiesKey = 'ziesocial_local_stories';

  List<StoryModel> _stories = [];
  StreamSubscription<List<StoryModel>>? _storiesSub;

  StoryViewModel() {
    _restoreStoriesFromStorage();
    bindStories();
  }

  void bindStories() {
    if (_storiesSub != null) return;
    _storiesSub = FirestoreStoryService.watchStories().listen(
      (remoteStories) {
        if (remoteStories.isNotEmpty) {
          for (final s in remoteStories) {
            final saved = LoginViewModel.getSavedProfile(s.author.id);
            if (saved != null) {
              s.author = AuthorModel(
                id: s.author.id,
                username: saved['username']?.toString().isNotEmpty == true
                    ? saved['username'].toString()
                    : s.author.username,
                name: saved['name']?.toString().isNotEmpty == true
                    ? saved['name'].toString()
                    : s.author.name,
                avatar: saved['avatar']?.toString() ?? s.author.avatar,
                isVerified: s.author.isVerified,
              );
            }
          }
          _stories = remoteStories;
        } else {
          _stories.removeWhere((s) => s.id != 101);
          if (_stories.isEmpty) {
            _seedDefaultStories();
          }
        }
        _saveStoriesToStorage();
        notifyListeners();
      },
      onError: (e) {
        debugPrint('StoryViewModel stream error: $e');
      },
    );
  }

  @override
  void dispose() {
    _storiesSub?.cancel();
    super.dispose();
  }

  List<StoryModel> get stories => List.unmodifiable(_stories);

  // Mengambil cerita aktif (belum kedaluwarsa 24 jam)
  List<StoryModel> get activeStories {
    return _stories.where((s) => !s.isExpired).toList();
  }

  // Mengambil daftar cerita milik author tertentu
  List<StoryModel> getStoriesForAuthor(int authorId) {
    return activeStories.where((s) => s.author.id == authorId).toList();
  }

  // Cek apakah author memiliki cerita yang belum dilihat oleh user aktif
  bool hasUnviewedStories(int authorId, int currentUserId) {
    final authorStories = getStoriesForAuthor(authorId);
    if (authorStories.isEmpty) return false;
    return authorStories.any((s) => !s.isViewedBy(currentUserId));
  }

  // Mengambil daftar author unik yang memiliki cerita aktif
  List<AuthorModel> getAuthorsWithStories(int currentUserId) {
    final Map<int, AuthorModel> authorMap = {};
    for (final story in activeStories) {
      if (!authorMap.containsKey(story.author.id)) {
        authorMap[story.author.id] = story.author;
      }
    }

    final list = authorMap.values.toList();
    // Urutkan: author dengan cerita yang belum dilihat berada di depan
    list.sort((a, b) {
      final aUnviewed = hasUnviewedStories(a.id, currentUserId);
      final bUnviewed = hasUnviewedStories(b.id, currentUserId);
      if (aUnviewed && !bUnviewed) return -1;
      if (!aUnviewed && bUnviewed) return 1;
      return 0;
    });

    return list;
  }

  // Tambah cerita baru
  Future<void> addStory({
    required AuthorModel author,
    required String mediaUrl,
    String? caption,
  }) async {
    final newStory = StoryModel(
      id: DateTime.now().microsecondsSinceEpoch,
      author: author,
      mediaUrl: mediaUrl,
      caption: caption,
      createDate: DateTime.now().toIso8601String(),
      viewedByUserIds: {author.id}, // Pembuat otomatis sudah melihat ceritanya
    );

    _stories.removeWhere((s) => s.id == 101);
    _stories.insert(0, newStory);
    _saveStoriesToStorage();
    notifyListeners();

    await FirestoreStoryService.addStory(newStory);
  }

  // Hapus cerita
  Future<void> deleteStory(int storyId) async {
    _stories.removeWhere((s) => s.id == storyId);
    _saveStoriesToStorage();
    notifyListeners();
    await FirestoreStoryService.deleteStory(storyId);
  }

  // Tandai cerita sudah dilihat oleh user tertentu
  Future<void> markStoryViewed(int storyId, int userId) async {
    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index != -1) {
      if (!_stories[index].viewedByUserIds.contains(userId)) {
        _stories[index].viewedByUserIds.add(userId);
        _saveStoriesToStorage();
        notifyListeners();
        await FirestoreStoryService.markStoryViewed(storyId, userId);
      }
    }
  }

  // Sinkronisasi profil author (nama & avatar) ke cerita yang dibuat
  void syncAuthorProfile({
    required int userId,
    String? name,
    String? avatar,
    bool updateAvatar = false,
  }) {
    bool changed = false;
    for (final story in _stories) {
      if (story.author.id == userId) {
        if (name != null && name.isNotEmpty) {
          story.author.name = name;
          changed = true;
        }
        if (updateAvatar) {
          story.author.avatar = avatar;
          changed = true;
        }
      }
    }
    if (changed) {
      _saveStoriesToStorage();
      notifyListeners();
    }
  }

  void _restoreStoriesFromStorage() {
    try {
      LoginViewModel.ensureStorageLoaded();
      final raw = LocalStorage.getString(_storiesKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _stories = decoded
              .map((item) => StoryModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }

      // Jika belum ada cerita sama sekali, buat cerita selamat datang dari ZieSocial Official
      if (_stories.isEmpty) {
        _seedDefaultStories();
      }
    } catch (_) {
      if (_stories.isEmpty) {
        _seedDefaultStories();
      }
    }
  }

  void _seedDefaultStories() {
    final officialAuthor = AuthorModel(
      id: 9999,
      username: 'ziesocial.id',
      name: 'ZieSocial Official',
      avatar: 'assets/images/logo.png',
      isVerified: true,
    );

    _stories = [
      StoryModel(
        id: 101,
        author: officialAuthor,
        mediaUrl: 'assets/images/logo.png',
        caption: 'Selamat datang di fitur Cerita (Story) ZieSocial! 🎉',
        createDate: DateTime.now().toIso8601String(),
        viewedByUserIds: {},
      ),
    ];
    _saveStoriesToStorage();
  }

  void _saveStoriesToStorage() {
    try {
      final serialized = _stories.map((s) => s.toJson()).toList();
      LocalStorage.setString(_storiesKey, jsonEncode(serialized));
    } catch (_) {}
  }
}

