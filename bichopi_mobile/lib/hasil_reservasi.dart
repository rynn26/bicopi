import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HasilReservasiScreen extends StatelessWidget {
  final String nama;
  final String tanggal;
  final String waktu;
  final String jumlah;
  final String keterangan;
  final String namaTempat;

  const HasilReservasiScreen({
    super.key,
    required this.nama,
    required this.tanggal,
    required this.waktu,
    required this.jumlah,
    required this.keterangan,
    required this.namaTempat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bukti Reservasi'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terima kasih, $nama!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Reservasi Anda untuk $namaTempat telah berhasil.'),
            const SizedBox(height: 20),
            const Text('Detail Reservasi:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Nama Pemesan: $nama'),
            Text('Tanggal Reservasi: $tanggal'),
            Text('Waktu Reservasi: $waktu'),
            Text('Jumlah Orang: $jumlah'),
            if (keterangan.isNotEmpty) Text('Keterangan: $keterangan'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _kirimKeWhatsApp(context),
                icon: const Icon(Icons.abc_rounded),
                label: const Text('Lanjutkan ke WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _kirimKeWhatsApp(BuildContext context) async {
    final pesan = Uri.encodeComponent('''
Halo, saya ingin konfirmasi reservasi:
📍 Tempat: $namaTempat
👤 Nama: $nama
📅 Tanggal: $tanggal
⏰ Waktu: $waktu
👥 Jumlah Orang: $jumlah
📝 Keterangan: ${keterangan.isEmpty ? '-' : keterangan}
''');

    const nomorTujuan = '6281230735844'; // Ganti dengan nomor tujuan
    final url = 'https://wa.me/$nomorTujuan?text=$pesan';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
      );
    }
  }
}
