import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../core/firestore_notification_service.dart';
import '../core/local_storage.dart';
import '../core/network.dart';
import '../model/post_model.dart';
import '../model/user_profile_model.dart';
import 'login_viewmodel.dart';

class FollowConnectionUser {
  final AuthorModel author;
  final String bio;
  bool isFollowing;

  FollowConnectionUser({
    required this.author,
    this.bio = '',
    this.isFollowing = false,
  });

  factory FollowConnectionUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '') ?? 0;
    final username = json['username']?.toString() ?? '';
    final name = json['name']?.toString() ?? username;
    final avatar = json['avatar']?.toString();
    return FollowConnectionUser(
      author: AuthorModel(
        id: id,
        username: username,
        name: name.isNotEmpty ? name : username,
        avatar: avatar,
        isVerified: username.toLowerCase() == 'ziesocial' ||
            username.toLowerCase() == 'ziesocial.id',
      ),
      bio: json['bio']?.toString() ?? '',
      isFollowing: json['is_following'] == true || json['is_following'] == 1,
    );
  }
}

class FollowConnectionsResult {
  final List<FollowConnectionUser> followers;
  final List<FollowConnectionUser> following;

  const FollowConnectionsResult({
    this.followers = const [],
    this.following = const [],
  });
}

class ProfileViewModel extends ChangeNotifier {
  static const String _followsKey = 'ziesocial_local_follows';

  final ApiClient _apiClient;

  ProfileViewModel(this._apiClient) {
    _loadFollowsFromStorage();
  }

  final Map<int, UserProfileModel> _profilesById = {};
  final Map<int, FollowConnectionsResult> _connectionsByUserId = {};
  final Set<int> _loadingUserIds = {};
  final Set<int> _loadingFollowListUserIds = {};
  final Map<int, Set<int>> _followingMap = {}; // followerId -> {followingIds}

  UserProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isLoadingUser(int userId) => _loadingUserIds.contains(userId);
  bool isLoadingFollowList(int userId) =>
      _loadingFollowListUserIds.contains(userId);
  FollowConnectionsResult connectionsFor(int userId) =>
      _connectionsByUserId[userId] ?? const FollowConnectionsResult();

  void _loadFollowsFromStorage() {
    try {
      final raw = LocalStorage.getString(_followsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            final followerId = int.tryParse(key.toString());
            if (followerId != null && value is List) {
              _followingMap[followerId] = value
                  .map((e) => int.tryParse(e.toString()) ?? 0)
                  .where((id) => id > 0)
                  .toSet();
            }
          });
        }
      }
    } catch (_) {}
  }

  void _saveFollowsToStorage() {
    try {
      final serialized = <String, List<int>>{};
      _followingMap.forEach((followerId, set) {
        serialized[followerId.toString()] = set.toList();
      });
      LocalStorage.setString(_followsKey, jsonEncode(serialized));
    } catch (_) {}
  }

  int _countFollowers(int targetUserId) {
    int count = 0;
    for (final entry in _followingMap.entries) {
      if (entry.key != targetUserId && entry.value.contains(targetUserId)) {
        count++;
      }
    }
    return count;
  }

  int _countFollowing(int targetUserId) {
    return _followingMap[targetUserId]?.length ?? 0;
  }

  bool _isUserFollowing(int followerId, int followingId) {
    return _followingMap[followerId]?.contains(followingId) ?? false;
  }

  bool isFollowing(int followerId, int followingId) =>
      _isUserFollowing(followerId, followingId);

  UserProfileModel _buildLocalProfile({
    required int targetUserId,
    required int currentUserId,
    AuthorModel? initialAuthor,
  }) {
    LoginViewModel.ensureStorageLoaded();
    final saved = LoginViewModel.getSavedProfile(targetUserId);

    String resolvedUsername = '';
    String resolvedName = '';
    String resolvedBio = 'Selamat datang di ZieSocial!';
    String? resolvedAvatar;

    if (saved != null) {
      resolvedUsername = saved['username']?.toString() ?? '';
      resolvedName = saved['name']?.toString() ?? '';
      resolvedBio =
          saved['bio']?.toString() ?? 'Selamat datang di ZieSocial!';
      resolvedAvatar = saved['avatar']?.toString();
    }

    if (initialAuthor != null) {
      if (resolvedUsername.isEmpty) resolvedUsername = initialAuthor.username;
      if (resolvedName.isEmpty) resolvedName = initialAuthor.name;
      if (resolvedAvatar == null || resolvedAvatar.isEmpty) {
        resolvedAvatar = initialAuthor.avatar;
      }
    }

    // Hanya gunakan data sesi login aktif jika memang melihat profil milik sendiri
    if (targetUserId == currentUserId) {
      if (resolvedUsername.isEmpty) {
        resolvedUsername = LoginViewModel.currentUsername ?? 'pengguna';
      }
      if (resolvedName.isEmpty) {
        resolvedName = LoginViewModel.currentUserName ?? 'Pengguna';
      }
      resolvedAvatar ??= LoginViewModel.currentUserAvatar;
    } else {
      if (resolvedUsername.isEmpty) {
        resolvedUsername = 'user_$targetUserId';
      }
      if (resolvedName.isEmpty) {
        resolvedName = resolvedUsername;
      }
    }

    return UserProfileModel(
      id: targetUserId,
      username: resolvedUsername,
      name: resolvedName,
      bio: resolvedBio,
      avatar: resolvedAvatar,
      postsCount: 0,
      followersCount: _countFollowers(targetUserId),
      followingCount: _countFollowing(targetUserId),
      isFollowing: _isUserFollowing(currentUserId, targetUserId),
      posts: const [],
    );
  }

  UserProfileModel getProfileFor({
    required int targetUserId,
    required int currentUserId,
    AuthorModel? initialAuthor,
  }) {
    final existing = _profilesById[targetUserId];
    if (existing != null) {
      existing.followersCount = _countFollowers(targetUserId);
      existing.followingCount = _countFollowing(targetUserId);
      existing.isFollowing = _isUserFollowing(currentUserId, targetUserId);
      return existing;
    }
    final built = _buildLocalProfile(
      targetUserId: targetUserId,
      currentUserId: currentUserId,
      initialAuthor: initialAuthor,
    );
    _profilesById[targetUserId] = built;
    return built;
  }

  // Mengambil data profil pengguna beserta statistik dan daftar postingan
  Future<void> fetchProfile({
    required int targetUserId,
    required int currentUserId,
    AuthorModel? initialAuthor,
  }) async {
    _isLoading = true;
    _loadingUserIds.add(targetUserId);
    _errorMessage = null;
    notifyListeners();

    try {
      final url =
          '${ApiConstants.userProfile}?user_id=$targetUserId&current_user_id=$currentUserId';
      final response = await _apiClient.get(url);
      UserProfileModel? parsed;
      if (response is Map<String, dynamic>) {
        parsed = UserProfileModel.fromJson(response);
      } else if (response is Map) {
        parsed =
            UserProfileModel.fromJson(Map<String, dynamic>.from(response));
      }
      if (parsed != null) {
        _profilesById[targetUserId] = parsed;
        _profile = parsed;
        if (targetUserId != currentUserId) {
          final set = _followingMap.putIfAbsent(currentUserId, () => <int>{});
          if (parsed.isFollowing) {
            set.add(targetUserId);
          } else {
            set.remove(targetUserId);
          }
          _saveFollowsToStorage();
        }
      }
    } catch (e) {
      final built = _buildLocalProfile(
        targetUserId: targetUserId,
        currentUserId: currentUserId,
        initialAuthor: initialAuthor,
      );
      _profilesById[targetUserId] = built;
      _profile = built;
      _errorMessage = null;
    } finally {
      _isLoading = false;
      _loadingUserIds.remove(targetUserId);
      notifyListeners();
    }
  }

  // Follow / Unfollow pengguna dengan optimistic update & penyimpanan lokal
  Future<bool> toggleFollow({
    required int followerId,
    required int followingId,
  }) async {
    if (followerId == followingId) return false;

    final currentSet = _followingMap.putIfAbsent(followerId, () => <int>{});
    final wasFollowing = currentSet.contains(followingId);

    if (wasFollowing) {
      currentSet.remove(followingId);
    } else {
      currentSet.add(followingId);
      FirestoreNotificationService.sendActivityNotification(
        recipientId: followingId,
        actorId: followerId,
        type: 'follow',
        body: 'mulai mengikuti Anda',
      );
    }
    _saveFollowsToStorage();

    final targetProfile = _profilesById[followingId];
    if (targetProfile != null) {
      targetProfile.isFollowing = !wasFollowing;
      targetProfile.followersCount = _countFollowers(followingId);
    }
    final myProfile = _profilesById[followerId];
    if (myProfile != null) {
      myProfile.followingCount = _countFollowing(followerId);
    }
    for (final entry in _connectionsByUserId.values) {
      for (final u in entry.followers) {
        if (u.author.id == followingId) {
          u.isFollowing = !wasFollowing;
        }
      }
      for (final u in entry.following) {
        if (u.author.id == followingId) {
          u.isFollowing = !wasFollowing;
        }
      }
    }
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.toggleFollow,
        body: {
          'follower_id': followerId,
          'following_id': followingId,
        },
      );

      if (targetProfile != null) {
        if (response['followers_count'] is int) {
          targetProfile.followersCount = response['followers_count'] as int;
        }
        if (response['is_following'] != null) {
          targetProfile.isFollowing = response['is_following'] == true;
        }
        notifyListeners();
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  // Update foto profil saja secara langsung
  Future<bool> updateAvatar({
    required int userId,
    required String? avatarDataUrl,
  }) async {
    final target = _profilesById[userId] ??
        _buildLocalProfile(targetUserId: userId, currentUserId: userId);
    target.avatar = avatarDataUrl;
    _profilesById[userId] = target;
    _profile = target;

    LoginViewModel.saveUserProfileEntry(
      id: userId,
      username: target.username,
      name: target.name,
      bio: target.bio,
      avatar: avatarDataUrl,
      updateAvatar: true,
    );
    notifyListeners();
    return true;
  }

  // Update profil (Nama, Bio, dan opsional Foto Profil)
  Future<bool> updateProfile({
    required int userId,
    required String name,
    required String bio,
    String? avatar,
    bool updateAvatar = false,
  }) async {
    final target = _profilesById[userId] ??
        _buildLocalProfile(targetUserId: userId, currentUserId: userId);
    target.name = name;
    target.bio = bio;
    if (updateAvatar) {
      target.avatar = avatar;
    }
    _profilesById[userId] = target;
    _profile = target;

    LoginViewModel.saveUserProfileEntry(
      id: userId,
      username: target.username,
      name: name,
      bio: bio,
      avatar: updateAvatar ? avatar : target.avatar,
      updateAvatar: updateAvatar,
    );
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.updateProfile,
        body: {
          'user_id': userId,
          'name': name,
          'bio': bio,
          if (updateAvatar) 'avatar': avatar,
        },
      );
      return true;
    } catch (e) {
      return true;
    }
  }

  FollowConnectionUser _buildLocalConnectionUser(
    int userId, {
    required int currentUserId,
  }) {
    final prof = _profilesById[userId];
    final saved = LoginViewModel.getSavedProfile(userId);
    final username = prof?.username ??
        saved?['username']?.toString() ??
        'user_$userId';
    final name = prof?.name ??
        saved?['name']?.toString() ??
        (username.isNotEmpty ? username : 'Pengguna $userId');
    final avatar = prof?.avatar ?? saved?['avatar']?.toString();
    final bio = prof?.bio ?? saved?['bio']?.toString() ?? '';
    return FollowConnectionUser(
      author: AuthorModel(
        id: userId,
        username: username,
        name: name,
        avatar: avatar,
        isVerified: username.toLowerCase() == 'ziesocial' ||
            username.toLowerCase() == 'ziesocial.id',
      ),
      bio: bio,
      isFollowing: _isUserFollowing(currentUserId, userId),
    );
  }

  List<FollowConnectionUser> _parseConnectionList(
    dynamic rawList,
    int currentUserId,
  ) {
    if (rawList is! List) return [];
    final results = <FollowConnectionUser>[];
    for (final item in rawList) {
      if (item is Map) {
        final user = FollowConnectionUser.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (user.author.id > 0) {
          LoginViewModel.saveUserProfileEntry(
            id: user.author.id,
            username: user.author.username,
            name: user.author.name,
            bio: user.bio,
            avatar: user.author.avatar,
          );
          final set = _followingMap.putIfAbsent(currentUserId, () => <int>{});
          if (user.isFollowing) {
            set.add(user.author.id);
          } else if (user.author.id != currentUserId) {
            set.remove(user.author.id);
          }
          results.add(user);
        }
      }
    }
    return results;
  }

  Future<FollowConnectionsResult> fetchFollowConnections({
    required int targetUserId,
    required int currentUserId,
  }) async {
    _loadingFollowListUserIds.add(targetUserId);
    notifyListeners();

    try {
      final url =
          '${ApiConstants.followsList}?user_id=$targetUserId&current_user_id=$currentUserId';
      final response = await _apiClient.get(url);
      if (response is Map) {
        final followers = _parseConnectionList(
          response['followers'],
          currentUserId,
        );
        final following = _parseConnectionList(
          response['following'],
          currentUserId,
        );
        _saveFollowsToStorage();

        final result = FollowConnectionsResult(
          followers: followers,
          following: following,
        );
        _connectionsByUserId[targetUserId] = result;

        final cachedProf = _profilesById[targetUserId];
        if (cachedProf != null) {
          cachedProf.followersCount = followers.length;
          cachedProf.followingCount = following.length;
        }
        return result;
      }
    } catch (_) {
      // Fallback ke data lokal saat offline
    } finally {
      _loadingFollowListUserIds.remove(targetUserId);
      notifyListeners();
    }

    final localFollowerIds = <int>[];
    for (final entry in _followingMap.entries) {
      if (entry.key != targetUserId && entry.value.contains(targetUserId)) {
        localFollowerIds.add(entry.key);
      }
    }
    final localFollowingIds =
        (_followingMap[targetUserId] ?? const <int>{}).toList();

    final fallback = FollowConnectionsResult(
      followers: localFollowerIds
          .map((id) => _buildLocalConnectionUser(id, currentUserId: currentUserId))
          .toList(),
      following: localFollowingIds
          .map((id) => _buildLocalConnectionUser(id, currentUserId: currentUserId))
          .toList(),
    );
    _connectionsByUserId[targetUserId] = fallback;
    notifyListeners();
    return fallback;
  }
}
