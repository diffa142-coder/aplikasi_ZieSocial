import 'package:card_design/card/ayat_card1.dart';
import 'package:card_design/viewmodel/ayar_viewmodel1.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// View bertugas menampilkan tampilan aplikasi.
class AyatView extends StatelessWidget {
  const AyatView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Membuat ViewModel dan langsung menjalankan
      // fungsi getAyar() ketika halaman dibuat.
      create: (_) => AyarViewmodel1()..getAyar(),

      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ayar'),
        ),
        // Consumer digunakan agar View dapat
        // menerima perubahan data dari ViewModel.
        body: Consumer<AyarViewmodel1>(
          builder: (context, viewModel, child) {
            // Menampilkan Loading ketika API sedang dipanggil.
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Menampilkan pesan jika terjadi error.
            if (viewModel.errorMessage != null) {
              return Center(
                child: Text(viewModel.errorMessage!),
              );
            }

            // Menampilkan daftar kontak setelah data berhasil
            // didapatkan dari API.
            return ListView.builder(
              padding: const EdgeInsets.all(8),

              // Jumlah item berdasarkan jumlah kontak.
              itemCount: viewModel.ayat.length,

              // Membuat CardContact untuk setiap kontak.
              itemBuilder: (context, index) {
                // Mengambil data kontak berdasarkan index.
                final ayat = viewModel.ayat[index];

                // Mengirim data kontak ke CardContact.
                return CardAyat(
                  nomorAyat: ayat.nomorAyat.toString(),
                  teksArab: ayat.teksArab,
                  teksLatin: ayat.teksLatin,
                  teksIndonesia: ayat.teksIndonesia,
                );
              },
            );
          },
        ),
      ),
    );
  }
}