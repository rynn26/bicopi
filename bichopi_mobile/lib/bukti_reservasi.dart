import 'package:flutter/material.dart';

class HasilReservasiScreen extends StatelessWidget {
  final String nama;
  final String tanggal;
  final String waktu;
  final String jumlah;
  final String keterangan;

  const HasilReservasiScreen({
    super.key,
    required this.nama,
    required this.tanggal,
    required this.waktu,
    required this.jumlah,
    required this.keterangan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservasi"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Announcement
            const Text(
              "Announcement",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Screenshot bukti reservasi dan kirimkan bukti kepada WhatsApp untuk melakukan konfirmasi dan pembayaran.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Gambar & Detail Singkat
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/kursi.jpg', // Ganti dengan path gambar yang benar
                      width: 90,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kursi Deretan Depan",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Kapasitas 20 Orang",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail Reservasi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Detail Reservasi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow("Nama", nama),
                  _buildDetailRow("Tanggal", tanggal),
                  _buildDetailRow("Waktu", waktu),
                  _buildDetailRow("Jumlah", jumlah),
                  _buildDetailRow("Keterangan", keterangan.isNotEmpty ? keterangan : "Tidak ada keterangan"),
                ],
              ),
            ),

            const Spacer(),

            // Tombol Hubungi Sekarang
            Center(
              child: TextButton(
                onPressed: () {
                  // Tambahkan logika untuk menghubungi WhatsApp
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/whatsapp.png', // Pastikan gambar tersedia
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text("Hubungi Sekarang", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.black)),
        ],
      ),
    );
  }
}