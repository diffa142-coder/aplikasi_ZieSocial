import 'package:flutter/material.dart';

class CardList extends StatelessWidget {
  const CardList({super.key});

  @override
  Widget build(BuildContext context) {
    // Card utama
    return Card(
      elevation: 2,

      // Membuat sudut Card melengkung
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

      child: Container(
        // Lebar Card
        width: double.infinity,

        // Tinggi Card
        height: 80,

        // Jarak isi dengan pinggir Card
        padding: const EdgeInsets.all(12),

        child: Row(
          children: [
            // =========================
            // ICON DI SEBELAH KIRI
            // =========================
            Container(
              // Ukuran tempat icon
              width: 55,
              height: 55,

              // Membuat icon berbentuk lingkaran
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),

              // Icon binoculars
              child: const Icon(Icons.search, color: Colors.blue, size: 35),
            ),

            // Jarak antara icon dan tulisan
            const SizedBox(width: 15),

            // =========================
            // BAGIAN TEKS
            // =========================
            Expanded(
              child: Column(
                // Membuat teks rata kiri
                crossAxisAlignment: CrossAxisAlignment.start,

                // Membuat isi berada di tengah secara vertikal
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  // Judul
                  const Text(
                    'Title Menu 1',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  // Jarak antara judul dan deskripsi
                  const SizedBox(height: 3),

                  // Deskripsi
                  const Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing',
                    maxLines: 1,

                    // Jika teks terlalu panjang, akan menjadi ...
                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // =========================
            // ICON PANAH
            // =========================
            const Icon(
              Icons.chevron_right,

              // Ukuran icon panah
              size: 30,

              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
