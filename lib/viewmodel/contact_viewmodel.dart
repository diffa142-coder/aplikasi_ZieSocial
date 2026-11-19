import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/contact_model.dart';

// ViewModel bertugas sebagai penghubung antara View
// dengan sumber data/API.
class ContactViewModel extends ChangeNotifier {
  // Menyimpan seluruh data kontak yang didapat dari API.
  List<ContactModel> contacts = [];

  // Menentukan apakah proses mengambil data sedang berlangsung.
  bool isLoading = false;

  // Menyimpan pesan error jika request gagal.
  String? errorMessage;

  // Fungsi untuk mengambil data kontak dari API.
  Future<void> getContacts() async {
    // Sebelum request dimulai, ubah loading menjadi true.
    isLoading = true;

    // Hapus error sebelumnya.
    errorMessage = null;

    // Memberitahu View bahwa ada perubahan data.
    notifyListeners();

    try {
      // Mengirim request GET ke endpoint JSON.
      final response = await http.get(
        Uri.parse(
          'https://apitest.smkn1cianjur.sch.id/contacts.json',
        ),
      );

      // Jika server memberikan status 200,
      // berarti data berhasil didapatkan.
      if (response.statusCode == 200) {
        // Mengubah response JSON menjadi List.
        final List data = jsonDecode(response.body);

        // Mengubah setiap data JSON menjadi ContactModel.
        contacts = data
            .map(
              (item) => ContactModel.fromJson(item),
            )
            .toList();
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