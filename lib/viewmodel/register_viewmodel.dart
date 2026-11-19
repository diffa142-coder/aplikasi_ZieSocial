import 'package:flutter/foundation.dart';
import 'package:card_design/core/constants.dart'; // PERUBAHAN: ziegram -> card_design
import 'package:card_design/core/firestore_chat_service.dart';
import 'package:card_design/core/network.dart'; // PERUBAHAN: ziegram -> card_design
import 'package:card_design/viewmodel/login_viewmodel.dart';

// ===== BARU: ViewModel untuk fitur register =====
class RegisterViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  RegisterViewModel(this._apiClient);

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;

    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        body: {
          'name': name,
          'username': username,
          'email': email,
          'password': password,
        },
      );

      _successMessage = response['message'];

      final fallbackId = LoginViewModel.generateUserId(
        username.trim().isNotEmpty ? username.trim() : email.trim(),
      );
      FirestoreChatService.syncUser(
        id: fallbackId,
        username: username.trim(),
        name: name.trim(),
        bio: 'Selamat datang di ZieSocial!',
      );

      return true;
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Failed to fetch') ||
          errStr.contains('SocketException') ||
          errStr.contains('timeout') ||
          errStr.contains('ClientException')) {
        LoginViewModel.ensureStorageLoaded();
        final lowerEmail = email.trim().toLowerCase();
        final lowerUsername = username.trim().toLowerCase();

        // Cek apakah email atau username sudah pernah didaftarkan
        for (final existing in LoginViewModel.localAccounts.values) {
          final existingEmail = existing['email']?.toString().toLowerCase();
          final existingUsername =
              existing['username']?.toString().toLowerCase();
          if (existingEmail == lowerEmail) {
            _errorMessage =
                'Email sudah terdaftar. Silakan login atau gunakan email lain.';
            return false;
          }
          if (existingUsername == lowerUsername) {
            _errorMessage =
                'Username sudah digunakan. Silakan gunakan username lain.';
            return false;
          }
        }

        final uniqueId = LoginViewModel.generateUserId(
          username.trim().isNotEmpty ? username.trim() : email.trim(),
        );
        LoginViewModel.localAccounts[lowerEmail] = {
          'id': uniqueId,
          'name': name.trim(),
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
        };
        LoginViewModel.saveLocalAccounts();
        LoginViewModel.saveUserProfileEntry(
          id: uniqueId,
          username: username.trim(),
          name: name.trim(),
          bio: 'Selamat datang di ZieSocial!',
        );
        FirestoreChatService.syncUser(
          id: uniqueId,
          username: username.trim(),
          name: name.trim(),
          bio: 'Selamat datang di ZieSocial!',
        );
        _successMessage = 'Registrasi berhasil! Silakan login.';
        _errorMessage = null;
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