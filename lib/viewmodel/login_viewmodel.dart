import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:card_design/core/constants.dart';
import 'package:card_design/core/firestore_chat_service.dart';
import 'package:card_design/core/local_storage.dart';
import 'package:card_design/core/network.dart';

class LoginViewModel extends ChangeNotifier {
  static const String _sessionKey = 'ziesocial_user_session';
  static const String _accountsKey = 'ziesocial_local_accounts';
  static const String _profilesKey = 'ziesocial_local_profiles';

  final ApiClient _apiClient;

  // Penyimpanan akun & profil lokal per pengguna jika backend sedang offline
  static final Map<String, Map<String, dynamic>> localAccounts = {};
  static final Map<int, Map<String, dynamic>> localProfiles = {};

  static int? currentUserIdStatic;
  static String? currentUserName;
  static String? currentUsername;
  static String? currentUserAvatar;

  LoginViewModel(this._apiClient) {
    _restoreFromStorage();
  }

  bool _isLoading = false;
  String? _errorMessage;
  int? _userId;
  String? _name;
  String? _username;
  String? _avatar;
  String? _bio;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get userId => _userId;
  bool get isLoggedIn => _userId != null;
  int get activeUserId => _userId ?? 1;
  String get name => _name ?? 'Pengguna';
  String get username => _username ?? '';
  String? get avatar => _avatar;
  String? get bio => _bio;

  /// Menghasilkan ID unik konsisten berdasarkan username agar setiap akun memiliki ID berbeda.
  static int generateUserId(String seed) {
    final normalized = seed.trim().toLowerCase();
    if (normalized.isEmpty) return 100;
    int hash = 5381;
    for (int i = 0; i < normalized.length; i++) {
      hash = ((hash << 5) + hash) ^ normalized.codeUnitAt(i);
      hash &= 0x3FFFFFFF;
    }
    return (hash % 900000) + 100;
  }

  static void ensureStorageLoaded() {
    if (localProfiles.isEmpty) {
      final rawProfiles = LocalStorage.getString(_profilesKey);
      if (rawProfiles != null && rawProfiles.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawProfiles);
          if (decoded is Map) {
            decoded.forEach((key, value) {
              final id = int.tryParse(key.toString());
              if (id != null && value is Map) {
                localProfiles[id] = Map<String, dynamic>.from(value);
              }
            });
          }
        } catch (_) {}
      }
    }

    if (localAccounts.isEmpty) {
      final rawAccounts = LocalStorage.getString(_accountsKey);
      if (rawAccounts != null && rawAccounts.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawAccounts);
          if (decoded is Map) {
            decoded.forEach((key, value) {
              if (value is Map) {
                final map = Map<String, dynamic>.from(value);
                final uname = map['username']?.toString() ?? key.toString();
                int id = map['id'] is int
                    ? map['id'] as int
                    : int.tryParse(map['id']?.toString() ?? '') ?? 0;
                if (id <= 1) {
                  id = generateUserId(uname);
                  map['id'] = id;
                }
                localAccounts[key.toString()] = map;
                localProfiles.putIfAbsent(id, () => {
                      'id': id,
                      'username': uname,
                      'name': map['name']?.toString() ?? uname,
                      'bio': map['bio']?.toString() ??
                          'Selamat datang di ZieSocial!',
                      'avatar': map['avatar'],
                    });
              }
            });
          }
        } catch (_) {}
      }
    }
  }

  void _restoreFromStorage() {
    try {
      ensureStorageLoaded();
      saveLocalAccounts();
      saveLocalProfiles();

      final rawSession = LocalStorage.getString(_sessionKey);
      if (rawSession != null && rawSession.isNotEmpty) {
        final session = jsonDecode(rawSession);
        if (session is Map) {
          final uname = session['username']?.toString() ?? '';
          int? parsedId = session['id'] is int
              ? session['id'] as int
              : int.tryParse(session['id']?.toString() ?? '');
          if (parsedId != null && parsedId <= 1 && uname.isNotEmpty) {
            parsedId = generateUserId(uname);
          }

          _userId = parsedId;
          final savedProfile =
              _userId != null ? localProfiles[_userId!] : null;

          _name = savedProfile?['name']?.toString() ??
              session['name']?.toString();
          _username = savedProfile?['username']?.toString() ?? uname;
          _avatar = savedProfile?['avatar']?.toString() ??
              session['avatar']?.toString();
          _bio = savedProfile?['bio']?.toString() ??
              session['bio']?.toString();

          currentUserIdStatic = _userId;
          currentUserName = _name;
          currentUsername = _username;
          currentUserAvatar = _avatar;

          if (_userId != null) {
            saveUserProfileEntry(
              id: _userId!,
              username: _username ?? '',
              name: _name ?? 'Pengguna',
              bio: _bio,
              avatar: _avatar,
            );
            _saveSession();
            FirestoreChatService.syncUser(
              id: _userId!,
              username: _username ?? '',
              name: _name ?? 'Pengguna',
              bio: _bio,
              avatar: _avatar,
            );
          }
        }
      }
    } catch (_) {
      // Abaikan jika gagal decode data lama
    }
  }

  void _saveSession() {
    if (_userId == null) return;
    try {
      LocalStorage.setString(
        _sessionKey,
        jsonEncode({
          'id': _userId,
          'name': _name,
          'username': _username,
          'avatar': _avatar,
          'bio': _bio,
        }),
      );
    } catch (_) {}
  }

  static void saveLocalAccounts() {
    try {
      LocalStorage.setString(_accountsKey, jsonEncode(localAccounts));
    } catch (_) {}
  }

  static void saveLocalProfiles() {
    try {
      final stringKeyed = <String, dynamic>{};
      localProfiles.forEach((key, value) {
        stringKeyed[key.toString()] = value;
      });
      LocalStorage.setString(_profilesKey, jsonEncode(stringKeyed));
    } catch (_) {}
  }

  static void saveUserProfileEntry({
    required int id,
    required String username,
    required String name,
    String? bio,
    String? avatar,
    bool updateAvatar = false,
  }) {
    ensureStorageLoaded();
    final existing = localProfiles[id] ?? <String, dynamic>{};
    localProfiles[id] = {
      ...existing,
      'id': id,
      'username': username.isNotEmpty
          ? username
          : (existing['username']?.toString() ?? ''),
      'name': name.isNotEmpty
          ? name
          : (existing['name']?.toString() ?? 'Pengguna'),
      'bio': bio ?? existing['bio'] ?? 'Selamat datang di ZieSocial!',
      'avatar': updateAvatar ? avatar : (avatar ?? existing['avatar']),
    };

    // Sinkronkan juga ke localAccounts jika ada akun dengan ID yang sama
    for (final entry in localAccounts.entries) {
      if (entry.value['id'] == id) {
        if (name.isNotEmpty) entry.value['name'] = name;
        if (bio != null) entry.value['bio'] = bio;
        if (updateAvatar || avatar != null) entry.value['avatar'] = avatar;
      }
    }

    saveLocalProfiles();
    saveLocalAccounts();
  }

  static Map<String, dynamic>? getSavedProfile(int userId) {
    ensureStorageLoaded();
    if (localProfiles.containsKey(userId)) {
      return localProfiles[userId];
    }
    for (final acc in localAccounts.values) {
      if (acc['id'] == userId) {
        return acc;
      }
    }
    return null;
  }

  void updateActiveUser({
    String? name,
    String? bio,
    String? avatar,
    bool updateAvatar = false,
  }) {
    if (name != null && name.isNotEmpty) {
      _name = name;
      currentUserName = name;
    }
    if (bio != null) {
      _bio = bio;
    }
    if (updateAvatar) {
      _avatar = avatar;
      currentUserAvatar = avatar;
    }
    if (_userId != null) {
      saveUserProfileEntry(
        id: _userId!,
        username: _username ?? '',
        name: _name ?? 'Pengguna',
        bio: _bio,
        avatar: _avatar,
        updateAvatar: updateAvatar,
      );
      _saveSession();
      FirestoreChatService.syncUser(
        id: _userId!,
        username: _username ?? '',
        name: _name ?? 'Pengguna',
        bio: _bio,
        avatar: _avatar,
      );
    }
    notifyListeners();
  }

  void logout() {
    _userId = null;
    _name = null;
    _username = null;
    _avatar = null;
    _bio = null;
    currentUserIdStatic = null;
    currentUserName = null;
    currentUsername = null;
    currentUserAvatar = null;
    LocalStorage.remove(_sessionKey);
    LocalStorage.remove('ziesocial_profile_name');
    LocalStorage.remove('ziesocial_profile_bio');
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        body: {
          'email': email,
          'password': password,
        },
      );

      final user = response['user'];

      if (user is Map) {
        if (user['id'] != null) {
          _userId = int.tryParse(user['id'].toString());
        }
        _name = user['name']?.toString();
        _username = user['username']?.toString();
        _avatar = user['avatar']?.toString();
        _bio = user['bio']?.toString();
        currentUserIdStatic = _userId;
        currentUserName = _name;
        currentUsername = _username;
        currentUserAvatar = _avatar;
      }

      if (_userId == null) {
        _errorMessage = 'ID pengguna tidak ditemukan dari API';
        return false;
      }

      saveUserProfileEntry(
        id: _userId!,
        username: _username ?? '',
        name: _name ?? 'Pengguna',
        bio: _bio,
        avatar: _avatar,
      );
      _saveSession();
      FirestoreChatService.syncUser(
        id: _userId!,
        username: _username ?? '',
        name: _name ?? 'Pengguna',
        bio: _bio,
        avatar: _avatar,
      );
      return true;
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Failed to fetch') ||
          errStr.contains('SocketException') ||
          errStr.contains('timeout') ||
          errStr.contains('ClientException')) {
        ensureStorageLoaded();
        final key = email.trim().toLowerCase();

        // Cari akun tersimpan berdasarkan email atau username
        Map<String, dynamic>? saved = localAccounts[key];
        if (saved == null) {
          for (final acc in localAccounts.values) {
            final accEmail = acc['email']?.toString().toLowerCase();
            final accUsername = acc['username']?.toString().toLowerCase();
            if (accEmail == key || accUsername == key) {
              saved = acc;
              break;
            }
          }
        }

        // Jika akun tidak ditemukan di daftar registrasi, tolak login!
        if (saved == null) {
          _errorMessage =
              'Akun belum terdaftar. Silakan registrasi (buat akun) terlebih dahulu.';
          return false;
        }

        // Validasi password akun
        if (saved['password'] != password) {
          _errorMessage = 'Password salah. Silakan periksa kembali.';
          return false;
        }

        final uname = saved['username']?.toString() ?? key;
        int id = saved['id'] is int
            ? saved['id'] as int
            : int.tryParse(saved['id']?.toString() ?? '') ?? 0;
        if (id <= 1) {
          id = generateUserId(uname);
          saved['id'] = id;
        }
        final profileData = localProfiles[id];
        _userId = id;
        _name = profileData?['name']?.toString() ??
            saved['name']?.toString() ??
            uname;
        _username = uname;
        _avatar = profileData?['avatar']?.toString() ??
            saved['avatar']?.toString();
        _bio = profileData?['bio']?.toString() ??
            saved['bio']?.toString() ??
            'Selamat datang di ZieSocial!';

        currentUserIdStatic = _userId;
        currentUserName = _name;
        currentUsername = _username;
        currentUserAvatar = _avatar;
        _errorMessage = null;

        saveUserProfileEntry(
          id: _userId!,
          username: _username ?? '',
          name: _name ?? 'Pengguna',
          bio: _bio,
          avatar: _avatar,
        );
        _saveSession();
        FirestoreChatService.syncUser(
          id: _userId!,
          username: _username ?? '',
          name: _name ?? 'Pengguna',
          bio: _bio,
          avatar: _avatar,
        );
        return true;
      }

      _errorMessage = errStr.replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
