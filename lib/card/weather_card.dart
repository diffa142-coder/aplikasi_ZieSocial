import 'package:flutter/material.dart';

class CardWeather extends StatelessWidget {
  const CardWeather({super.key});

  @override
  Widget build(BuildContext context) {
    return const WeatherCard();
  }
}

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      // Mengatur bayangan Card
      elevation: 4,

      // Membuat sudut Card melengkung
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      child: Container(
        // Lebar Card mengikuti layar HP
        // 90% dari lebar layar
        width: MediaQuery.of(context).size.width * 0.90,

        // Tinggi Card
        height: 190,

        // Jarak isi dengan pinggir Card
        padding: const EdgeInsets.all(12),

        child: Column(
          children: [
            // =========================
            // BAGIAN ATAS
            // =========================
            Row(
              children: [
                // =========================
                // ICON CUACA
                // =========================
                SizedBox(
                  width: 120,
                  height: 85,

                  child: Stack(
                    alignment: Alignment.center,

                    children: [
                      // Matahari
                      const Positioned(
                        left: 5,
                        top: 0,

                        child: Icon(
                          Icons.wb_sunny,

                          // Ukuran diperkecil
                          size: 65,

                          color: Colors.amber,
                        ),
                      ),

                      // Awan
                      const Positioned(
                        right: 5,
                        bottom: 15,

                        child: Icon(
                          Icons.cloud,

                          // Ukuran diperkecil
                          size: 65,

                          color: Colors.grey,
                        ),
                      ),

                      // Hujan
                      Positioned(
                        right: 15,
                        bottom: 0,

                        child: Row(
                          children: const [
                            // Tetes air 1
                            Icon(
                              Icons.water_drop,
                              size: 15,
                              color: Colors.blue,
                            ),

                            SizedBox(width: 5),

                            // Tetes air 2
                            Icon(
                              Icons.water_drop,
                              size: 15,
                              color: Colors.blue,
                            ),

                            SizedBox(width: 5),

                            // Tetes air 3
                            Icon(
                              Icons.water_drop,
                              size: 15,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Jarak antara icon dan tulisan
                const SizedBox(width: 8),

                // =========================
                // LOCATION DAN CIANJUR
                // =========================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: const [
                      // Tulisan Location
                      Text(
                        "Location",

                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 2),

                      // Nama kota
                      Text(
                        "Cianjur",

                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // =========================
            // DATA CUACA
            // =========================
            Row(
              // Membagi ruang secara merata
              mainAxisAlignment: MainAxisAlignment.spaceAround,

              children: const [
                // Wind
                WeatherData(title: "Wind", value: "250"),

                // Temperature
                WeatherData(title: "Temp", value: "17"),

                // Humidity
                WeatherData(title: "Humid", value: "27%"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// Widget untuk data cuaca
// ========================================

class WeatherData extends StatelessWidget {
  final String title;
  final String value;

  const WeatherData({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Nama data
        Text(
          title,

          style: const TextStyle(
            // Diperkecil dari 20 menjadi 11
            fontSize: 11,

            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 3),

        // Nilai data
        Text(
          value,

          style: const TextStyle(
            // Diperkecil dari 32 menjadi 16
            fontSize: 16,

            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
