class ApiConstants {
  static const String _ngrokDomain = 'https://prong-pancreas-lance.ngrok-free.dev';

  static String get host => _ngrokDomain;

  static String get baseSiteUrl => '$_ngrokDomain/ziesocial';

  static String get baseUrl => '$baseSiteUrl/api';

  static String get login => '$baseUrl/auth/login.php';
  static String get register => '$baseUrl/auth/register.php';
  static String get createPost => '$baseUrl/posts/create.php';
  static String get readPosts => '$baseUrl/posts/read.php';
  static String get updatePost => '$baseUrl/posts/update.php';
  static String get deletePost => '$baseUrl/posts/delete.php';

  static String get toggleLike => '$baseUrl/likes/toggle.php';

  static String get createComment => '$baseUrl/comments/create.php';
  static String get readComments => '$baseUrl/comments/read.php';
  static String get deleteComment => '$baseUrl/comments/delete.php';

  static String get toggleFollow => '$baseUrl/follows/toggle.php';
  static String get followsList => '$baseUrl/follows/list.php';
  static String get userProfile => '$baseUrl/users/profile.php';
  static String get updateProfile => '$baseUrl/users/update_profile.php';
  static String get registerFcmToken => '$baseUrl/notifications/register_token.php';
  static String get pushNotification => '$baseUrl/notifications/push.php';

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('data:')) return path;
    if (path.startsWith('assets/') || path.startsWith('/assets/')) {
      return path.startsWith('/') ? path.substring(1) : path;
    }
    if (path.startsWith('http://localhost/ziesocial/')) {
      return path.replaceFirst('http://localhost/ziesocial', baseSiteUrl);
    }
    if (path.startsWith('http://192.168.2.100/ziesocial/')) {
      return path.replaceFirst('http://192.168.2.100/ziesocial', baseSiteUrl);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$baseSiteUrl/$cleanPath';
  }
}
