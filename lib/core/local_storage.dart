import 'local_storage_stub.dart'
    if (dart.library.io) 'local_storage_io.dart'
    if (dart.library.html) 'local_storage_web.dart';

class LocalStorage {
  static String? getString(String key) => getStorageItem(key);

  static void setString(String key, String value) => setStorageItem(key, value);

  static void remove(String key) => removeStorageItem(key);
}

