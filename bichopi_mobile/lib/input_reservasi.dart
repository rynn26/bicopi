import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  // Initialize Supabase
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL', // Ganti dengan URL Supabase Anda
    anonKey: 'YOUR_SUPABASE_ANON_KEY', // Ganti dengan anon key Supabase Anda
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
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Slightly more rounded
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green[700]!, width: 2), // Thicker on focus
          ),
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIconColor: Colors.green[700], // Consistent icon color
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            elevation: 3, // Add a slight elevation
          ),
        ),
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

  @override
  void initState() {
    super.initState();
    // Initialize Supabase in main() instead of here for global access.
    // Ensure you replace 'YOUR_SUPABASE_URL' and 'YOUR_SUPABASE_ANON_KEY'
    // in main()
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.green[700],
            colorScheme: ColorScheme.light(primary: Colors.green[700]!),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      tanggalController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.green[700],
            colorScheme: ColorScheme.light(primary: Colors.green[700]!),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
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
        const SnackBar(
            content: Text('Harap isi semua field yang diperlukan.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    final timeRegex = RegExp(r'^\d{2}:\d{2}$');

    if (!dateRegex.hasMatch(tanggal) || !timeRegex.hasMatch(waktu)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Format tanggal atau waktu tidak valid.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.from('reservasii').insert({
        'nama_pengguna': nama,
        'tanggal': _formatDateForSupabase(tanggal),
        'waktu': waktu,
        'jumlah_orang': jumlah,
        'keterangan': keterangan,
        'nama_tempat': namaTempat,
        'created_at': DateTime.now().toIso8601String(),
      }).select(); // Use .select() to get the inserted data if needed, or remove if not.

      if (response == null || response.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal menyimpan reservasi.'),
              backgroundColor: Colors.red),
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

        // Clear controllers after successful submission and navigation
        namaController.clear();
        tanggalController.clear();
        waktuController.clear();
        jumlahController.clear();
        keteranganController.clear();
      }
    } catch (error) {
      print('Error menyimpan reservasi: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Terjadi kesalahan: $error'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDateForSupabase(String dateString) {
    final parts = dateString.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}'; // YYYY-MM-DD
    }
    return dateString;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Lighter background
      appBar: AppBar(
        title: Text(
          'Reservasi ${widget.category['name']}',
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buat Reservasi Anda', // More engaging title
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
              child: Text(
                'Lengkapi detail di bawah ini untuk memesan di ${widget.category['name']}.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1), // Softer shadow
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
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
                    hintText: 'Catatan tambahan seperti preferensi meja, dll.',
                    controller: keteranganController,
                    icon: Icons.note_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      )
                    : ElevatedButton.icon(
                        onPressed: _submitReservation,
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: const Text(
                          'Konfirmasi Reservasi',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF078603), // Warna latar hijau
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
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
          prefixIcon: Icon(icon), // Icon color handled by InputDecorationTheme
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
      backgroundColor: Colors.grey[50], // Consistent background
      appBar: AppBar(
        title: const Text('Bukti Reservasi'),
        backgroundColor: Color(0xFF078603),
        foregroundColor: Colors.white, // White text for AppBar title
        elevation: 0, // Flat app bar for a cleaner look
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center content
          children: [
            Icon(Icons.check_circle, color: Color(0xFF078603), size: 80),
            const SizedBox(height: 10),
            Text(
              'Reservasi Berhasil!',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Terima kasih, $nama! Reservasi Anda untuk $namaTempat akan dikonfirmasi lebih lanjut.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30), // More space before card
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // Consistent rounding
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0), // Increased padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Nama Pemesan:', nama, Icons.person_outline),
                    _buildDetailRow('Tanggal Reservasi:', tanggal, Icons.calendar_today_outlined),
                    _buildDetailRow('Waktu Reservasi:', waktu, Icons.access_time_outlined),
                    _buildDetailRow('Jumlah Orang:', jumlah, Icons.people_outline),
                    if (keterangan.isNotEmpty)
                      _buildDetailRow('Keterangan:', keterangan, Icons.note_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _kirimKeWhatsApp(context),
              icon: Image.asset('assets/whatsapp.png',width: 24, height: 24, color: Colors.white, // opsional: jika ikon PNG transparan dan kamu ingin warnanya putih
),
                label: const Text('Lanjutkan ke WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF078603), // WhatsApp Green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 10),
             SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst); // Go back to the first screen (e.g., home)
                },
                icon: const Icon(Icons.home_outlined, color: Colors.green),
                label: const Text('Kembali ke Beranda'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: Colors.green[700]!, width: 2), // Green border
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green[700], size: 22),
          const SizedBox(width: 12),
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
              textAlign: TextAlign.right, // Align value to the right
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

    const nomorTujuan = '6281230735844'; // Ganti dengan nomor tujuan Anda

    final url = Uri.parse(
        'https://wa.me/$nomorTujuan?text=${Uri.encodeComponent(pesan)}');

    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
        print("WhatsApp terbuka");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tidak dapat membuka WhatsApp. Pastikan aplikasi terinstall.'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Terjadi kesalahan saat membuka WhatsApp.'),
            backgroundColor: Colors.red),
      );
      print("Error launching WhatsApp: $e");
    }
  }
}