import 'dart:math'; // Untuk generateUniqueId sebagai fallback
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:coba3/reedem_up.dart'; // Pastikan path ini benar untuk PopupPage Anda

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  _RewardPageState createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  int currentPoints = 0;
  bool isLoading = true;
  List<Map<String, dynamic>> rewards = [];

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() {
      isLoading = true;
    });
    await fetchCurrentPoints();
    await fetchRewards();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchCurrentPoints() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        print("Pengguna belum login.");
        setState(() {
          currentPoints = 0;
        });
        return;
      }

      final response = await supabase
          .from('member_points_log')
          .select('points_earned')
          .eq('member_id', user.id);

      int total = 0;
      if (response.isNotEmpty) {
        for (final row in response) {
          total += row['points_earned'] as int;
        }
      }

      if (!mounted) return;
      setState(() {
        currentPoints = total;
      });
    } catch (e) {
      print("Error mengambil poin: $e");
      if (!mounted) return;
      setState(() {
        currentPoints = 0;
      });
    }
  }

  // Fungsi untuk mencatat penukaran dan menampilkan popup
  Future<void> redeemReward(String rewardId, String rewardTitle, int pointsToDeduct) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User belum login.");
      }

      // 1. Catat transaksi penukaran ke tabel 'penukaran_point'
      // Menangkap respons untuk mendapatkan ID yang dibuat oleh database
      final List<Map<String, dynamic>> response = await supabase.from('penukaran_point').insert({
        'member_id': user.id,
        'penukaran_point': pointsToDeduct,
        // Anda bisa menambahkan 'redeemed_at': DateTime.now().toIso8601String(), jika diperlukan
      }).select('id'); // Memilih kolom 'id' dari hasil insert

      String newTransactionId = '';
      if (response.isNotEmpty) {
        newTransactionId = response[0]['id'].toString(); // Ambil ID dari respons Supabase
      } else {
        // Fallback jika ID tidak bisa didapatkan (misal: Supabase tidak mengembalikan ID secara langsung)
        newTransactionId = generateUniqueId();
        print("Warning: Could not get ID from Supabase insert response. Using fallback ID.");
      }

      // 2. BAGIAN INI DIKOMENTARI AGAR POIN TIDAK BERKURANG
      /*
      await supabase.from('member_points_log').insert({
        'member_id': user.id,
        'points_earned': -pointsToDeduct,
        'description': 'Penukaran reward: "$rewardTitle"',
        'created_at': DateTime.now().toIso8601String(),
      });
      */

      // 3. Muat ulang poin saat ini (meskipun poin tidak berkurang, tetap panggil untuk konsistensi UI)
      await fetchCurrentPoints();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reward \"$rewardTitle\" berhasil diklaim!", style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );

      // Setelah proses redeem, tampilkan popup dengan newTransactionId
      if (mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: true,
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) {
              return PopupPage( // Menggunakan PopupPage
                title: rewardTitle,
                points: pointsToDeduct,
                transactionId: newTransactionId, // Meneruskan ID dari Supabase
              );
            },
            transitionsBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation, Widget child) {
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
      }
    } catch (e) {
      print("Error saat menukarkan reward: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengklaim reward. Coba lagi nanti: $e", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> deductPoints(int points, String rewardTitle, String rewardId) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User belum login.");
      }

      await supabase.from('member_points_log').insert({
        'member_id': user.id,
        'points_earned': -points,
        'description': 'Poin ditukarkan untuk "$rewardTitle"',
        'created_at': DateTime.now().toIso8601String(),
        'reward_id': rewardId,
        'redeemed_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        currentPoints -= points;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Poin berhasil ditukarkan untuk \"$rewardTitle\"!", style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error mengurangi poin: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menukar poin. Coba lagi nanti.", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> fetchRewards() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('klaim_rewards')
          .select('id, judul, deskripsi, points, status')
          .eq('status', 'setuju');



      if (response.isEmpty) {

        setState(() {
          rewards = [];
        });
      } else {
        setState(() {
          rewards = List<Map<String, dynamic>>.from(response.map((item) => {
                "id": item["id"].toString(),
                "title": item["judul"],
                "description": item["deskripsi"],
                "points": item["points"],
              }));
        });
      }
    } catch (e) {
      print("Error mengambil rewards: $e");
      setState(() {
        rewards = [];
      });
    }
  }

  Future<bool> hasRedeemedRecently(String rewardId) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

      final response = await supabase
          .from('member_points_log')
          .select('id')
          .eq('member_id', user.id)
          .eq('reward_id', rewardId)
          .gte('redeemed_at', oneWeekAgo)
          .limit(1);

      return response != null && response.isNotEmpty;
    } catch (e) {
      print("Error memeriksa klaim sebelumnya: $e");
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF078603), Color(0xFF078603)],
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
                            color: const Color(0xFF4CAF50),
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
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : rewards.isEmpty
                    ? Center(
                        child: Text(
                          "Tidak ada reward tersedia.",
                          style: GoogleFonts.poppins(),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rewards.length,
                        itemBuilder: (context, index) {
                          final reward = rewards[index];
                          return _buildRewardCard(
                            context,
                            reward["id"] ?? "",
                            reward["title"] ?? "",
                            reward["points"] ?? 0,
                            reward["description"] ?? "",
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, String rewardId, String title, int points, String description) {
    // Logika ini tetap memeriksa poin agar reward hanya bisa diklaim jika poin cukup,
    // meskipun poinnya sendiri tidak berkurang setelah klaim.
    final bool canRedeem = currentPoints >= points;

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
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: canRedeem ? () => showRedeemDialog(context, rewardId, title, points) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canRedeem ? const Color(0xFF4CAF50) : Colors.grey[400],
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

  void showRedeemDialog(BuildContext context, String rewardId, String title, int points) async {
    // Logika ini masih akan mengecek apakah poin cukup untuk mengklaim.
    if (currentPoints < points) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Poin Tidak Cukup"),
            content: const Text("Maaf, poin Anda tidak cukup untuk menukar reward ini."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    // Tidak perlu generateUniqueId di sini lagi karena akan diambil dari Supabase
    // String transactionId = generateUniqueId(); // Dihapus atau dikomentari

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Konfirmasi Klaim Reward",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Text(
            "Apakah Anda yakin ingin mengklaim reward \"$title\"?",
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
              onPressed: () async {
                Navigator.pop(context); // Tutup dialog konfirmasi
                // Panggil redeemReward yang sekarang akan menampilkan PopupPage dengan ID dari Supabase
                await redeemReward(rewardId, title, points);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4CAF50),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              child: const Text("Klaim"),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      },
    );
  }

  // Fungsi fallback untuk generate ID unik jika Supabase tidak mengembalikan ID langsung
  String generateUniqueId() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int random = Random().nextInt(900) + 100; // Angka acak 100-999
    return "#$timestamp$random";
  }
}