import 'dart:convert';

import 'package:card_design/model/ayar_model1.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ViewModel bertugas sebagai penghubung antara View
// dengan sumber data/API.
class AyarViewmodel1 extends ChangeNotifier {
  // Menyimpan seluruh data kontak yang didapat dari API.
  List<Ayatmodel> ayat = [];

  // Menentukan apakah proses mengambil data sedang berlangsung.
  bool isLoading = false;

  // Menyimpan pesan error jika request gagal.
  String? errorMessage;

  // Fungsi untuk mengambil data kontak dari API.
  Future<void> getAyar() async {
    // Sebelum request dimulai, ubah loading menjadi true.
    isLoading = true;

    // Hapus error sebelumnya.
    errorMessage = null;

    // Memberitahu View bahwa ada perubahan data.
    notifyListeners();

    try {
      // Mengirim request GET ke endpoint JSON.
      final response = await http.get(
        Uri.parse('https://equran.id/api/v2/surat/1'),
      );

      // Jika server memberikan status 200,
      // berarti data berhasil didapatkan.
      if (response.statusCode == 200) {
        // Mengubah response body menjadi Map.
        final Map<String, dynamic> json = jsonDecode(response.body);

        // Mengubah response JSON menjadi List.
        final List data = json['data']['ayat'];

        // Mengubah setiap data JSON menjadi ContactModel.
        ayat = data.map((item) => Ayatmodel.fromJson(item)).toList();
      } else {
        // Jika status bukan 200, tampilkan pesan error.
        errorMessage = 'Gagal mengambil data';
      }
    } catch (e) {
      // Menangkap error seperti koneksi internet,
      // URL salah, atau error lainnya.
      errorMessage = e.toString();
    }

    // Request selesai, matikan loading.
    isLoading = false;

    // Memberitahu View untuk memperbarui tampilan.
    notifyListeners();
  }
}
