import 'package:flutter/material.dart';

class CardAyat extends StatelessWidget {
  final String nomorAyat;
  final String teksArab;
  final String teksLatin;
  final String teksIndonesia;

  const CardAyat({
    super.key,
    required this.nomorAyat,
    required this.teksArab,
    required this.teksLatin,
    required this.teksIndonesia,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(nomorAyat.toString()),
        Text(teksArab),
        Text(teksLatin),
        Text(teksIndonesia),
      ],
    );
  }
}