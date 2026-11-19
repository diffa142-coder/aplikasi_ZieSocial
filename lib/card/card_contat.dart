import 'package:flutter/material.dart';

class CardContact extends StatelessWidget {
  final String name;
  final String phone;
  final String avatar;

  // Callback yang akan dijalankan ketika tombol chat ditekan
  final VoidCallback onChatTap;

  const CardContact({
    super.key,
    required this.name,
    required this.phone,
    required this.avatar,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(avatar),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(phone, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            InkWell(
              // Menjalankan fungsi untuk membuka chat WhatsApp dari View
              onTap: onChatTap,
              child: Icon(Icons.chat),
            ),
          ],
        ),
      ),
    );
  }
}