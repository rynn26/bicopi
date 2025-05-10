import 'package:flutter/material.dart';

class PopupPage extends StatelessWidget {
  final String title;
  final int points;
  final String transactionId; // Tambahkan transactionId

  const PopupPage(
      {super.key,
      required this.title,
      required this.points,
      required this.transactionId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.grey.shade50, // Warna latar belakang
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 50, color: Colors.black),
            const SizedBox(height: 12),

            // Judul
            const Text(
              "Tanda Terima Penukaran",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Garis panjang pemisah setelah judul
            const Divider(thickness: 1.2, color: Colors.black38),

            const SizedBox(height: 12),

            // ID Penukaran
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "ID Penukaran",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(transactionId,
                  style: const TextStyle(color: Colors.black87)),
            ),

            const SizedBox(height: 16),

            // Penukaran Poin
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Penukaran Point",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.sync, size: 18),
                const SizedBox(width: 6),
                Text("$points POIN", style: const TextStyle(fontSize: 16)),
              ],
            ),

            const SizedBox(height: 16),

            // Garis panjang sebelum tombol Close
            const Divider(thickness: 1.2, color: Colors.black38),

            const SizedBox(height: 12),

            // Tombol Close (Lebar lebih pendek)
            SizedBox(
              width: 120, // Lebar tombol lebih pendek
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green, // Warna teks hijau
                  side: const BorderSide(
                      color: Colors.green, width: 2), // Border hijau
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  "Close",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
