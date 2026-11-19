
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const Map<String, String> _baseHeaders = {
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  dynamic _parseResponse(http.Response response, String fallbackError) {
    dynamic data;
    bool validJson = false;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
        validJson = true;
      } catch (_) {
        data = null;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (data is Map && data.containsKey('message')) {
        throw Exception(data['message']);
      }
      throw Exception('$fallbackError (Status: ${response.statusCode})');
    }

    if (!validJson) {
      throw Exception(
        '$fallbackError: respons server bukan JSON yang valid (pastikan MySQL aktif).',
      );
    }

    return data;
  }

  // Request GET untuk mengambil data seperti daftar postingan.
  Future<dynamic> get(String url) async {
    final response = await http
        .get(
          Uri.parse(url),
          headers: _baseHeaders,
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception(
            'Koneksi server timeout. Pastikan ngrok, MySQL, dan Apache berjalan.',
          ),
        );

    return _parseResponse(response, 'Gagal memuat data');
  }

  // Request JSON untuk login dan register.
  Future<Map<String, dynamic>> post(
    String url, {
    required Map<String, dynamic> body,
  }) async {
    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            ..._baseHeaders,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception(
            'Koneksi server timeout. Pastikan ngrok, MySQL, dan Apache berjalan.',
          ),
        );

    final data = _parseResponse(response, 'Terjadi kesalahan');
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }

  // BARU: Request multipart untuk upload gambar postingan (Mendukung Web & Mobile).
  Future<Map<String, dynamic>> upload(
    String url, {
    List<int>? fileBytes,
    String? filename,
    String? filePath,
    required String fieldName,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(url),
    );
    request.headers.addAll(_baseHeaders);

    // Tambahkan data teks, seperti user_id dan caption.
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Tambahkan file gambar.
    if (fileBytes != null) {
      // Bekerja di semua platform termasuk Flutter Web.
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          fileBytes,
          filename: filename ?? 'upload.jpg',
        ),
      );
    } else if (filePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          filePath,
        ),
      );
    }

    // Kirim request dan baca respons server dengan timeout.
    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception(
        'Koneksi upload timeout. Pastikan ngrok, MySQL, dan Apache berjalan.',
      ),
    );
    final response = await http.Response.fromStream(
      streamedResponse,
    );

    final data = _parseResponse(response, 'Gagal mengunggah data');
    return (data is Map<String, dynamic>) ? data : {'message': 'Success'};
  }
}