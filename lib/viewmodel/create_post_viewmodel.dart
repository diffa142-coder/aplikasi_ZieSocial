import 'package:card_design/core/constants.dart';
import 'package:card_design/core/network.dart';
import 'package:flutter/foundation.dart';

class CreatePostViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  CreatePostViewModel(this._apiClient);

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Mengirim postingan ke API (Mendukung Web via fileBytes & Mobile).
  Future<bool> createPost({
    required int userId,
    List<int>? fileBytes,
    String? filename,
    String? imagePath,
    String caption = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.upload(
        ApiConstants.createPost,
        fileBytes: fileBytes,
        filename: filename,
        filePath: imagePath,
        fieldName: 'image',
        fields: {
          'user_id': userId.toString(),
          'caption': caption,
        },
      );

      _successMessage = response['message']?.toString();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst(
        'Exception: ',
        '',
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}