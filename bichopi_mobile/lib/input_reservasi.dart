import 'package:flutter/material.dart';
import 'bukti_reservasi.dart';

class ReservationFormScreen extends StatefulWidget {
  final Map<String, dynamic> category; // Tambahkan parameter category

  const ReservationFormScreen({super.key, required this.category});

  @override
  _ReservationFormScreenState createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController tanggalController = TextEditingController();
  final TextEditingController waktuController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();
  final TextEditingController keteranganController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          'Reservasi - ${widget.category['name']}', // Menampilkan kategori
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambahkan Data Reservasi untuk ${widget.category['name']}',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            buildTextField('Nama', namaController, 'Nama Pemesan'),
            buildTextField('Tanggal Reservasi', tanggalController, 'Tanggal', Icons.calendar_today),
            buildTextField('Waktu Reservasi', waktuController, 'Waktu'),
            buildTextField('Jumlah Orang', jumlahController, 'Jumlah Orang'),
            buildTextField('Keterangan', keteranganController, 'Tambahkan keterangan (opsional)'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HasilReservasiScreen(
                        nama: namaController.text,
                        tanggal: tanggalController.text,
                        waktu: waktuController.text,
                        jumlah: jumlahController.text,
                        keterangan: keteranganController.text,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Cetak Reservasi',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, String hint, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: icon != null ? Icon(icon, color: Colors.green) : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}