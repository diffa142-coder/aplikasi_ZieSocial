import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

final Map<int, Uint8List> _dataUrlBytesCache = {};

Uint8List? _decodeDataUrl(String dataUrl) {
  final cacheKey = dataUrl.hashCode;
  final cached = _dataUrlBytesCache[cacheKey];
  if (cached != null) return cached;

  try {
    final uriData = UriData.parse(dataUrl);
    final bytes = uriData.contentAsBytes();
    if (_dataUrlBytesCache.length > 80) {
      _dataUrlBytesCache.clear();
    }
    _dataUrlBytesCache[cacheKey] = bytes;
    return bytes;
  } catch (_) {
    try {
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex != -1) {
        final bytes = base64Decode(dataUrl.substring(commaIndex + 1));
        if (_dataUrlBytesCache.length > 80) {
          _dataUrlBytesCache.clear();
        }
        _dataUrlBytesCache[cacheKey] = bytes;
        return bytes;
      }
    } catch (_) {}
  }
  return null;
}

Map<String, String>? _headersForUrl(String url) {
  if (url.contains('ngrok')) {
    return const {'ngrok-skip-browser-warning': 'true'};
  }
  return null;
}

ImageProvider? resolveSmartImageProvider(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('data:')) {
    final bytes = _decodeDataUrl(url);
    return bytes != null ? MemoryImage(bytes) : null;
  }
  if (url.startsWith('assets/')) {
    return AssetImage(url);
  }
  return NetworkImage(url, headers: _headersForUrl(url));
}

Widget buildSmartImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  ImageLoadingBuilder? loadingBuilder,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  if (url.startsWith('data:')) {
    final bytes = _decodeDataUrl(url);
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
    if (errorBuilder != null) {
      return Builder(
        builder: (ctx) =>
            errorBuilder(ctx, Exception('Format gambar tidak valid'), null),
      );
    }
    return const SizedBox.shrink();
  }

  if (url.startsWith('assets/')) {
    return Image.asset(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }

  return Image.network(
    url,
    width: width,
    height: height,
    fit: fit,
    headers: _headersForUrl(url),
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
  );
}

