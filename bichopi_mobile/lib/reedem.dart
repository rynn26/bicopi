import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reedem_up.dart';

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  _RewardPageState createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  int currentPoints = 0; // Poin yang akan diambil dari Supabase
  bool isLoading = true; // Menandakan data sedang diambil

  final List<Map<String, dynamic>> rewards = [
    {"title": "Gratis Kopi", "points": 150},
    {"title": "Gratis Teh", "points": 200},
    {"title": "Diskon 50%", "points": 250},
    {"title": "Voucher Rp50.000", "points": 300},
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

    // Ganti 'order_id' dengan kolom yang sesuai
    final response = await supabase
        .from('member_points_log') // Pastikan nama tabel benar
        .select('points_earned') // Kolom poin yang ingin diambil
        .eq('member_id', user.id); // Ganti 'order_id' dengan kolom yang sesuai

    if (response == null || response.isEmpty) {
      throw Exception("Tidak ada data poin.");
    }

    // Cetak response untuk debugging
    print("Response: $response");

    int total = 0;
    for (final row in response) {
      total += row['points_earned'] as int;  // Pastikan kolom 'points_earned' sesuai
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
          color: Color(0xFF078603), // warna hijau
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Text(
              "Redeem Point",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ), // Menghilangkan tombol back
      body: Column(
        children: [
          // Kotak "Point Saat Ini"
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 6, spreadRadius: 1),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Point Saat Ini",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        "$currentPoints",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF078603),
                        ),
                      ),
              ],
            ),
          ),

          // ListView Rewards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return _buildRewardCard(
                    context, reward["title"], reward["points"]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, String title, int points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Dapatkan kopi reguler gratis di lokasi kami",
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("$points Points",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () => showRedeemDialog(context, title, points),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF078603),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text("Klaim reward",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menampilkan dialog konfirmasi klaim reward
  void showRedeemDialog(BuildContext context, String title, int points) {
    if (currentPoints < points) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Poin tidak cukup untuk klaim reward")),
      );
      return;
    }

    String transactionId = generateUniqueId();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi Penukaran"),
          content: Text("Tukar $points poin untuk $title?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  currentPoints -= points;
                });

                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PopupPage(
                      title: title,
                      points: points,
                      transactionId: transactionId,
                    ),
                  ),
                );
              },
              child: const Text("Ya"),
            ),
          ],
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