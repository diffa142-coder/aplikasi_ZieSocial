import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../card/card_contat.dart';
import '../viewmodel/contact_viewmodel.dart';

// View bertugas menampilkan tampilan aplikasi.
class ContactView extends StatelessWidget {
  const ContactView({super.key});

  // Fungsi untuk membuka whatsapp berdasarkan nomor kontak
  Future<void> openWhatsApp(String phone) async {
    // menghapus karakter selain nomor
    final phoneNumber = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // membuat URL whatsapp menggunakan nomor kontak
    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/$phoneNumber',
    );

    // mengecek apakah URL bisa dibuka
    if (await canLaunchUrl(whatsappUrl)) {
      // membuka whatsapp menggunakan aplikasi external
      await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Membuat ViewModel dan langsung menjalankan
      // fungsi getContacts() ketika halaman dibuat.
      create: (_) => ContactViewModel()..getContacts(),

      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contacts'),
        ),
        // Consumer digunakan agar View dapat
        // menerima perubahan data dari ViewModel.
        body: Consumer<ContactViewModel>(
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
              itemCount: viewModel.contacts.length,

              // Membuat CardContact untuk setiap kontak.
              itemBuilder: (context, index) {
                // Mengambil data kontak berdasarkan index.
                final contact = viewModel.contacts[index];

                // Mengirim data kontak ke CardContact.
                return CardContact(
                  name: contact.name,
                  phone: contact.phone,
                  avatar: contact.avatar,

                  // ketika tombol chat di card ditekan
                  // jalankan fungsi openWhatsApp
                  onChatTap: () {
                    openWhatsApp(contact.phone);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}