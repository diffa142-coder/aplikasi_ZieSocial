import 'dart:convert';
import 'dart:io';

final Map<String, String> _ioCache = {};
bool _loaded = false;
File? _cachedFile;

File? _getStorageFile() {
  if (_cachedFile != null) return _cachedFile;
  if (!Platform.isAndroid && !Platform.isIOS) return null;

  try {
    final appBaseDir = Directory.systemTemp.parent;
    final filesDir = Directory('${appBaseDir.path}/files');
    if (!filesDir.existsSync()) {
      filesDir.createSync(recursive: true);
    }
    _cachedFile = File('${filesDir.path}/ziesocial_local_storage.json');
    return _cachedFile;
  } catch (_) {
    try {
      _cachedFile =
          File('${Directory.systemTemp.path}/ziesocial_local_storage.json');
      return _cachedFile;
    } catch (_) {
      return null;
    }
  }
}

void _ensureLoaded() {
  if (_loaded) return;
  _loaded = true;
  final file = _getStorageFile();
  if (file == null) return;

  try {
    if (file.existsSync()) {
      final raw = file.readAsStringSync();
      if (raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (v != null) {
              _ioCache[k.toString()] = v.toString();
            }
          });
        }
      }
    }
  } catch (_) {}
}

void _persistToDisk() {
  final file = _getStorageFile();
  if (file == null) return;
  try {
    file.writeAsStringSync(jsonEncode(_ioCache), flush: true);
  } catch (_) {}
}

String? getStorageItem(String key) {
  _ensureLoaded();
  return _ioCache[key];
}

void setStorageItem(String key, String value) {
  _ensureLoaded();
  _ioCache[key] = value;
  _persistToDisk();
}

void removeStorageItem(String key) {
  _ensureLoaded();
  _ioCache.remove(key);
  _persistToDisk();
}

