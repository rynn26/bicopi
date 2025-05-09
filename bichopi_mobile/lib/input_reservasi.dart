import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
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

  bool _isLoading = false;

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      tanggalController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      final dt =
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      waktuController.text = DateFormat('HH:mm').format(dt);
    }
  }

  Future<void> _submitReservation() async {
    final nama = namaController.text.trim();
    final tanggal = tanggalController.text.trim();
    final waktu = waktuController.text.trim();
    final jumlah = jumlahController.text.trim();
    final keterangan = keteranganController.text.trim();
    final namaTempat = widget.category['name'];

    if (nama.isEmpty || tanggal.isEmpty || waktu.isEmpty || jumlah.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua field yang diperlukan.')),
      );
      return;
    }

    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    final timeRegex = RegExp(r'^\d{2}:\d{2}$');

    if (!dateRegex.hasMatch(tanggal) || !timeRegex.hasMatch(waktu)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format tanggal atau waktu tidak valid.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response =
          await Supabase.instance.client.from('reservasii').insert({
        'nama_pengguna': nama,
        'tanggal': _formatDateForSupabase(tanggal),
        'waktu': waktu,
        'jumlah_orang': jumlah,
        'keterangan': keterangan,
        'nama_tempat': namaTempat,
        'created_at': DateTime.now().toIso8601String(),
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

    setState(() => _isLoading = false);
  }

  String _formatDateForSupabase(String dateString) {
    final parts = dateString.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return dateString;
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
                    keyboardType: TextInputType.none,
                    onTap: _selectDate,
                  ),
                  _buildRoundedTextField(
                    labelText: 'Waktu Reservasi',
                    hintText: 'Format: HH:mm (24 jam)',
                    controller: waktuController,
                    icon: Icons.access_time_outlined,
                    keyboardType: TextInputType.none,
                    onTap: _selectTime,
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
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
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
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
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
        readOnly: onTap != null,
        onTap: onTap,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terima kasih, $nama!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Reservasi Anda untuk $namaTempat telah berhasil.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Nama Pemesan:', nama),
                    _buildDetailRow('Tanggal Reservasi:', tanggal),
                    _buildDetailRow('Waktu Reservasi:', waktu),
                    _buildDetailRow('Jumlah Orang:', jumlah),
                    if (keterangan.isNotEmpty)
                      _buildDetailRow('Keterangan:', keterangan),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _kirimKeWhatsApp(context),
                icon: const Icon(Icons.abc, color: Colors.white),
                label: const Text('Lanjutkan ke WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _kirimKeWhatsApp(BuildContext context) async {
    final pesan = '''
Halo, saya ingin konfirmasi reservasi:
📍 Tempat: $namaTempat
👤 Nama: $nama
📅 Tanggal: $tanggal
⏰ Waktu: $waktu
👥 Jumlah Orang: $jumlah
📝 Keterangan: ${keterangan.isEmpty ? '-' : keterangan}
''';

    const nomorTujuan = '6281230735844'; // Ganti dengan nomor tujuan

    // Membuat URL WhatsApp
    final url = Uri.parse(
        'https://wa.me/$nomorTujuan?text=${Uri.encodeComponent(pesan)}');

    try {
      // Menggunakan launchUrl pada versi terbaru url_launcher
      if (await launchUrl(url)) {
        print("WhatsApp terbuka");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Terjadi kesalahan saat membuka WhatsApp')),
      );
      print("Error launching WhatsApp: $e");
    }
  }
}
