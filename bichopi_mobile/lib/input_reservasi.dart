import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL', // Ganti dengan URL Supabase Anda
    anonKey: 'YOUR_SUPABASE_ANON_KEY', // Ganti dengan Anon Key Supabase Anda
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Reservasi',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const ReservationFormScreen(category: {'name': 'Nama Tempat'}),
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

  Future<void> _submitReservation() async {
    final nama = namaController.text;
    final tanggal = tanggalController.text; // Format: dd/mm/yyyy dari TextField
    final waktu = waktuController.text;   // Format: HH:mm (24 jam) dari TextField
    final jumlah = jumlahController.text;
    final keterangan = keteranganController.text;
    final namaTempat = widget.category['name'];

    if (nama.isEmpty || tanggal.isEmpty || waktu.isEmpty || jumlah.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua field yang diperlukan.')),
      );
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('reservasi')
          .insert({
        'nama_pengguna': nama,
        'tanggal': _formatDateForSupabase(tanggal), // Format ke<ctrl3348>-mm-dd
        'waktu': waktu, // Biarkan seperti yang diinput (format 24 jam) karena tipe data varchar
        'jumlah_orang': jumlah, // Biarkan sebagai string karena tipe data varchar
        'keterangan': keterangan,
        'created_at': DateTime.now().toIso8601String(), // Tambahkan timestamp
      }).select();

      if (response == null || response.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan reservasi.')),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HasilReservasiScreen(
              nama: nama,
              tanggal: tanggal,
              waktu: waktu,
              jumlah: jumlah,
              keterangan: keterangan,
              namaTempat: namaTempat,
            ),
          ),
        );

        namaController.clear();
        tanggalController.clear();
        waktuController.clear();
        jumlahController.clear();
        keteranganController.clear();
      }
    } catch (error) {
      print('Error menyimpan reservasi: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $error')),
      );
    }
  }

  String _formatDateForSupabase(String dateString) {
    final parts = dateString.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}'; // Konversi dd/mm/yyyy ke<ctrl3348>-mm-dd
    }
    return dateString; // Jika format tidak sesuai, kembalikan apa adanya (mungkin perlu validasi lebih lanjut)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Reservasi ${widget.category['name']}',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Isi Detail Reservasi',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildRoundedTextField(
                    labelText: 'Nama Pemesan',
                    hintText: 'Masukkan nama Anda',
                    controller: namaController,
                    icon: Icons.person_outline,
                  ),
                  _buildRoundedTextField(
                    labelText: 'Tanggal Reservasi',
                    hintText: 'Format: dd/mm/yyyy',
                    controller: tanggalController,
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.datetime, // Suggest keyboard for date input
                  ),
                  _buildRoundedTextField(
                    labelText: 'Waktu Reservasi',
                    hintText: 'Format: HH:mm (24 jam)',
                    controller: waktuController,
                    icon: Icons.access_time_outlined,
                    keyboardType: TextInputType.datetime, // Suggest keyboard for time input
                  ),
                  _buildRoundedTextField(
                    labelText: 'Jumlah Orang',
                    hintText: 'Masukkan jumlah orang',
                    controller: jumlahController,
                    icon: Icons.people_outline,
                    keyboardType: TextInputType.number,
                  ),
                  _buildRoundedTextField(
                    labelText: 'Keterangan (Opsional)',
                    hintText: 'Catatan tambahan',
                    controller: keteranganController,
                    icon: Icons.note_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _submitReservation,
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white),
                      label: const Text(
                        'Konfirmasi Reservasi',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundedTextField({
    required String labelText,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines = 1,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: false, // Set readOnly to false to allow manual input
        cursorColor: Colors.green[700],
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.green[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.green[700]!),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

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
            const Text('Detail Reservasi:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Nama Pemesan: $nama'),
            Text('Tanggal Reservasi: $tanggal'),
            Text('Waktu Reservasi: $waktu'),
            Text('Jumlah Orang: $jumlah'),
            if (keterangan.isNotEmpty) Text('Keterangan: $keterangan'),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kembali ke Beranda'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}