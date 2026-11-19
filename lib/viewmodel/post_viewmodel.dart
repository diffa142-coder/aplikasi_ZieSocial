import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../core/firestore_notification_service.dart';
import '../core/local_storage.dart';
import '../core/network.dart';
import '../model/comment_model.dart';
import '../model/post_model.dart';
import 'login_viewmodel.dart';

class PostViewModel extends ChangeNotifier {
  static const String _postsKey = 'ziesocial_local_posts';

  final ApiClient _apiClient;

  PostViewModel(this._apiClient) {
    _restorePostsFromStorage();
  }

  List<PostModel> _posts = [];
  final Map<int, List<CommentModel>> _localComments = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  void _restorePostsFromStorage() {
    try {
      LoginViewModel.ensureStorageLoaded();
      final raw = LocalStorage.getString(_postsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        _posts = PostModel.fromDynamicList(decoded);

        bool migrated = false;
        for (final post in _posts) {
          final author = post.author;
          if (author != null) {
            int resolvedId = author.id;
            if (resolvedId <= 1 && author.username.isNotEmpty) {
              resolvedId = LoginViewModel.generateUserId(author.username);
              migrated = true;
            }
            final savedProf = LoginViewModel.getSavedProfile(resolvedId);
            final updatedName = savedProf?['name']?.toString() ?? author.name;
            final updatedAvatar =
                savedProf?['avatar']?.toString() ?? author.avatar;

            post.author = AuthorModel(
              id: resolvedId,
              username: author.username,
              name: updatedName,
              avatar: updatedAvatar,
              isVerified: author.isVerified,
            );

            // Pastikan profil pembuat postingan terdaftar di penyimpanan profil lokal
            if (savedProf == null && author.username.isNotEmpty) {
              LoginViewModel.saveUserProfileEntry(
                id: resolvedId,
                username: author.username,
                name: updatedName,
                avatar: updatedAvatar,
              );
            }
          }
        }
        if (migrated) {
          _savePostsToStorage();
        }
      }
    } catch (_) {}
  }

  void syncAuthorProfile({
    required int userId,
    String? name,
    String? avatar,
    bool updateAvatar = false,
  }) {
    bool changed = false;
    for (final post in _posts) {
      if (post.author != null && post.author!.id == userId) {
        if (name != null && name.isNotEmpty) {
          post.author!.name = name;
          changed = true;
        }
        if (updateAvatar) {
          post.author!.avatar = avatar;
          changed = true;
        }
      }
    }
    if (changed) {
      _savePostsToStorage();
      notifyListeners();
    }
  }

  void _savePostsToStorage() {
    try {
      LocalStorage.setString(
        _postsKey,
        jsonEncode(_posts.map((p) => p.toJson()).toList()),
      );
    } catch (_) {}
  }

  void clearAllPosts() {
    _posts.clear();
    _localComments.clear();
    _errorMessage = null;
    LocalStorage.remove(_postsKey);
    notifyListeners();
  }

  void addLocalPost({
    required int userId,
    required String caption,
    required String imageUrl,
  }) {
    final newId = DateTime.now().millisecondsSinceEpoch;
    final activeUsername =
        LoginViewModel.currentUsername ?? 'ziesocial.id';
    final activeName =
        LoginViewModel.currentUserName ?? 'ZieSocial Official';
    final newPost = PostModel(
      id: newId,
      caption: caption,
      image: imageUrl,
      createDate: DateTime.now().toIso8601String(),
      author: AuthorModel(
        id: userId,
        username: activeUsername,
        name: activeName,
        avatar: LoginViewModel.currentUserAvatar,
      ),
      likeCount: 0,
      commentCount: 0,
      isLiked: false,
    );
    _posts.insert(0, newPost);
    _localComments[newId] = [];
    _savePostsToStorage();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Filter postingan berdasarkan caption, username, atau nama author
  List<PostModel> searchPosts(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _posts;
    return _posts.where((post) {
      final captionMatch = post.caption.toLowerCase().contains(q);
      final authorNameMatch =
          post.author?.name.toLowerCase().contains(q) ?? false;
      final usernameMatch =
          post.author?.username.toLowerCase().contains(q) ?? false;
      return captionMatch || authorNameMatch || usernameMatch;
    }).toList();
  }

  // 1. Mengambil daftar postingan dari API dengan status like untuk user saat ini
  Future<void> fetchPosts({int? currentUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = currentUserId != null
          ? '${ApiConstants.readPosts}?current_user_id=$currentUserId'
          : ApiConstants.readPosts;
      final dynamic response = await _apiClient.get(url);
      if (response is List ||
          (response is Map && response.containsKey('data'))) {
        _posts = PostModel.fromDynamicList(response);
        _savePostsToStorage();
      }
    } catch (e) {
      // Tetap tampilkan kondisi kosong tanpa error jika server backend belum menyala
      _errorMessage = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _snippet(String raw, [int maxLen = 70]) {
    final trimmed = raw.trim();
    if (trimmed.length <= maxLen) return trimmed;
    return '${trimmed.substring(0, maxLen)}...';
  }

  void _notifyPostActivity({
    required PostModel post,
    required int actorId,
    required String type,
    required String body,
  }) {
    final authorId = post.author?.id ?? 0;
    if (authorId <= 0 || authorId == actorId) return;
    FirestoreNotificationService.sendActivityNotification(
      recipientId: authorId,
      actorId: actorId,
      type: type,
      body: body,
      postId: post.id,
    );
  }

  // 1. Toggle Like / Hapus Like (Unlike) ke backend dengan optimistic update per pengguna
  Future<bool> toggleLike(int postId, int userId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return false;

    final post = _posts[index];
    final bool alreadyLiked = post.likedByUserIds.contains(userId);

    // Optimistic UI update per-user
    if (alreadyLiked) {
      post.likedByUserIds.remove(userId);
      if (post.likeCount > 0) {
        post.likeCount--;
      }
    } else {
      post.likedByUserIds.add(userId);
      post.likeCount++;
      final captionPreview = post.caption.trim();
      _notifyPostActivity(
        post: post,
        actorId: userId,
        type: 'like',
        body: captionPreview.isNotEmpty
            ? 'menyukai postingan Anda: "${_snippet(captionPreview)}"'
            : 'menyukai postingan Anda',
      );
    }
    post.isLiked = post.likedByUserIds.contains(userId);
    _savePostsToStorage();
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.toggleLike,
        body: {'user_id': userId, 'post_id': postId},
      );
      return true;
    } catch (e) {
      // Pertahankan perubahan lokal saat mode offline
      return true;
    }
  }

  // 2. Edit Postingan (Caption)
  Future<bool> editPost({
    required int postId,
    required int userId,
    required String newCaption,
  }) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index].caption = newCaption;
      _savePostsToStorage();
      notifyListeners();
    }

    try {
      await _apiClient.post(
        ApiConstants.updatePost,
        body: {
          'id': postId,
          'user_id': userId,
          'caption': newCaption,
        },
      );
      return true;
    } catch (e) {
      return index != -1;
    }
  }

  // 5. Hapus Postingan
  Future<bool> deletePost({
    required int postId,
    required int userId,
  }) async {
    _posts.removeWhere((p) => p.id == postId);
    _savePostsToStorage();
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.deletePost,
        body: {
          'id': postId,
          'user_id': userId,
        },
      );
      return true;
    } catch (e) {
      return true;
    }
  }

  // 3. Ambil daftar komentar untuk postingan tertentu
  Future<List<CommentModel>> fetchComments(int postId) async {
    try {
      final response = await _apiClient.get('${ApiConstants.readComments}?post_id=$postId');
      final List<dynamic> list = response is Map && response['data'] is List
          ? response['data']
          : (response is List ? response : []);
      final fetched = list
          .map((item) => CommentModel.fromJson(item as Map<String, dynamic>))
          .toList();
      _localComments[postId] = fetched;
      return fetched;
    } catch (e) {
      return List<CommentModel>.from(_localComments[postId] ?? []);
    }
  }

  // 3. Tambahkan komentar baru
  Future<CommentModel?> addComment({
    required int postId,
    required int userId,
    required String text,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.createComment,
        body: {
          'post_id': postId,
          'user_id': userId,
          'text': text,
        },
      );

      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index].commentCount++;
        _notifyPostActivity(
          post: _posts[index],
          actorId: userId,
          type: 'comment',
          body: 'mengomentari: "${_snippet(text)}"',
        );
        notifyListeners();
      }

      if (response['comment'] is Map) {
        return CommentModel.fromJson(response['comment'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      final fallbackComment = CommentModel(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: userId,
        postId: postId,
        text: text,
        createDate: DateTime.now().toIso8601String(),
        username: LoginViewModel.currentUsername ?? 'ziesocial.id',
        name: LoginViewModel.currentUserName ?? 'ZieSocial Official',
        avatar: LoginViewModel.currentUserAvatar,
      );
      _localComments.putIfAbsent(postId, () => []).add(fallbackComment);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index].commentCount++;
        _notifyPostActivity(
          post: _posts[index],
          actorId: userId,
          type: 'comment',
          body: 'mengomentari: "${_snippet(text)}"',
        );
        notifyListeners();
      }
      return fallbackComment;
    }
  }

  // 4. Hapus komentar
  Future<bool> deleteComment({
    required int commentId,
    required int postId,
    required int userId,
  }) async {
    _localComments[postId]?.removeWhere((c) => c.id == commentId);
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1 && _posts[index].commentCount > 0) {
      _posts[index].commentCount--;
      notifyListeners();
    }

    try {
      await _apiClient.post(
        ApiConstants.deleteComment,
        body: {
          'comment_id': commentId,
          'user_id': userId,
        },
      );
      return true;
    } catch (e) {
      return true;
    }
  }
}
