import 'dart:math';
import 'package:coba3/reedem_up.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'popup_page.dart'; // Import PopupPage

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  _RewardPageState createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  int currentPoints = 0; // Poin yang akan diambil dari Supabase
  bool isLoading = true; // Menandakan data sedang diambil

  final List<Map<String, dynamic>> rewards = [
    {"title": "Kopi Premium", "points": 150, "description": "Nikmati citarasa kopi pilihan dengan kualitas terbaik."},
    {"title": "Teh Herbal", "points": 200, "description": "Segarkan diri Anda dengan kehangatan teh herbal alami."},
    {"title": "Diskon 50% Produk Pilihan", "points": 250, "description": "Raih kesempatan emas untuk mendapatkan diskon 50%."},
    {"title": "Voucher Eksklusif Rp75.000", "points": 300, "description": "Voucher spesial senilai Rp75.000 untuk Anda."},
  ];

  @override
  void initState() {
    super.initState();
    fetchCurrentPoints();
  }

  // Fungsi untuk mengambil poin dari Supabase
  Future<void> fetchCurrentPoints() async {
    try {
      final supabase = Supabase.instance.client;

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User belum login.");
      }

      final response = await supabase
          .from('member_points_log') // Pastikan nama tabel benar
          .select('points_earned') // Kolom poin yang ingin diambil
          .eq('member_id', user.id); // Ganti 'member_id' dengan kolom yang sesuai

      if (response == null || response.isEmpty) {
        throw Exception("Tidak ada data poin.");
      }

      // Cetak response untuk debugging
      print("Response: $response");

      int total = 0;
      for (final row in response) {
        total += row['points_earned'] as int;   // Pastikan kolom 'points_earned' sesuai
      }

      setState(() {
        currentPoints = total;
        isLoading = false;
      });
    } catch (e) {
      print("Error mengambil poin: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // tinggi AppBar
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Text(
                "Redeem Point",
                style: GoogleFonts.robotoSlab(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Poin Anda Saat Ini",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  isLoading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)))
                      : Text(
                          "$currentPoints",
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Pilihan Rewards",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return _buildRewardCard(
                    context, reward["title"], reward["points"], reward["description"]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, String title, int points, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$points Poin",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => showRedeemDialog(context, title, points),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  child: Text(
                    "Klaim",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk menampilkan dialog konfirmasi klaim reward
  void showRedeemDialog(BuildContext context, String title, int points) {
    if (currentPoints < points) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Poin Anda tidak mencukupi untuk reward ini.",
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    String transactionId = generateUniqueId();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Konfirmasi Penukaran",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Text(
            "Apakah Anda yakin ingin menukar $points poin untuk mendapatkan $title?",
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Batal",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  currentPoints -= points; // Kurangi poin di sini!
                });

                Navigator.pop(context);
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    barrierDismissible: true,
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                      return PopupPage(
                        title: title,
                        points: points,
                        transactionId: transactionId,
                      );
                    },
                    transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              child: const Text("Tukar"),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      },
    );
  }

  /// Fungsi untuk membuat ID unik berdasarkan waktu + angka acak
  String generateUniqueId() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int random = Random().nextInt(900) + 100; // Angka acak 3 digit
    return "#$timestamp$random";
  }
}