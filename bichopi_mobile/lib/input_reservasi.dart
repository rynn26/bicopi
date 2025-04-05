import 'package:flutter/material.dart';
import 'bukti_reservasi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        inputDecorationTheme: InputDecorationTheme(
          floatingLabelStyle: const TextStyle(color: Color(0xFF078603)), // Label berubah hijau saat diklik
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF078603), width: 2),
          ),
        ),
      ),
      home: const ReservationFormScreen(category: {'name': 'Contoh Reservasi'}),
    );
  }
}

class ReservationFormScreen extends StatefulWidget {
  final Map<String, dynamic> category;

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
        backgroundColor: const Color(0xFF078603),
        elevation: 4,
        toolbarHeight: 80,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        title: Text(
          'Reservasi - ${widget.category['name']}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambahkan Data Reservasi untuk ${widget.category['name']}',
              style: const TextStyle(
                color: Color(0xFF078603),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    buildTextField('Nama', namaController, 'Nama Pemesan', Icons.person),
                    buildTextField('Tanggal Reservasi', tanggalController, 'Tanggal', Icons.calendar_today),
                    buildTextField('Waktu Reservasi', waktuController, 'Waktu', Icons.access_time),
                    buildTextField('Jumlah Orang', jumlahController, 'Jumlah Orang', Icons.people),
                    buildTextField('Keterangan', keteranganController, 'Tambahkan keterangan (opsional)', Icons.notes),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Cetak Reservasi
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF078603),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text(
                    'Cetak Reservasi',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        cursorColor: const Color(0xFF078603),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.green),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}
