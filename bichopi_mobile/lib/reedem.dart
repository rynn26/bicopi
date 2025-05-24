import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:coba3/reedem_up.dart'; // Pastikan path ini benar untuk PopupPage Anda

class RewardPage extends StatefulWidget {
  const RewardPage({super.key, required String memberId});

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

  @override
  void dispose() {
    // Pastikan untuk membersihkan sumber daya jika ada, meskipun untuk Supabase
    // tidak selalu diperlukan dispose client secara eksplisit di widget.
    super.dispose();
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
        if (mounted) {
          setState(() {
            currentPoints = 0;
          });
        }
        // Tampilkan pesan jika pengguna belum login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Anda belum login. Poin tidak dapat dimuat.",
                    style: GoogleFonts.poppins())),
          );
        }
        return;
      }

      // Fetch total_points directly from the 'members' table using 'id_user'
      final response = await supabase
          .from('members')
          .select('total_points')
          .eq('id_user',
              user.id) // <--- PERBAIKAN DI SINI: user_id menjadi id_user
          .single();

      if (!mounted) return;
      setState(() {
        currentPoints = response['total_points'] as int? ?? 0;
      });
    } catch (e) {
      print("Error mengambil poin dari tabel 'members': $e");
      if (!mounted) return;
      setState(() {
        currentPoints = 0;
      });
      // Tampilkan SnackBar untuk error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Gagal memuat poin Anda: $e",
                  style: GoogleFonts.poppins())),
        );
      }
    }
  }

  // Fungsi untuk mencatat penukaran
  Future<void> redeemReward(
      String rewardId, String rewardTitle, int pointsToDeduct) async {
    String? transactionId; // Deklarasikan di sini agar bisa diakses di luar try-catch
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User belum login.");
      }

      // Pengecekan poin tidak lagi relevan jika poin tidak berkurang.
      // Namun, jika Anda ingin tetap menampilkan notifikasi "poin tidak cukup"
      // meskipun poin tidak dikurangi, Anda bisa biarkan bagian ini.
      // Jika tidak, Anda bisa menghapusnya.
      // if (currentPoints < pointsToDeduct) {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(
      //         content: Text("Poin Anda tidak cukup untuk menukar reward ini.",
      //             style: GoogleFonts.poppins()),
      //         backgroundColor: Colors.orange,
      //       ),
      //     );
      //   }
      //   return;
      // }

      // Dapatkan member_id yang benar dari tabel 'members'
      final memberResponse = await supabase
          .from('members')
          .select('id')
          .eq('id_user', user.id)
          .single();

      if (memberResponse == null || memberResponse['id'] == null) {
        throw Exception("Profil member tidak ditemukan untuk user ini.");
      }

      final actualMemberId = memberResponse['id'] as String;

      // 1. Catat transaksi penukaran ke tabel 'penukaran_point'
      // Dan langsung ambil ID transaksi yang dihasilkan oleh database
      final List<Map<String, dynamic>> insertResponse =
          await supabase.from('penukaran_point').insert({
        'member_id': actualMemberId,
        'penukaran_point': pointsToDeduct, // Poin dicatat, tapi tidak dikurangi dari total
        // 'redeemed_at': DateTime.now().toIso8601String(), // Jika ada
      }).select('id'); // <-- Hanya pilih kolom 'id' yang baru disisipkan

      if (insertResponse.isEmpty || insertResponse.first['id'] == null) {
        throw Exception("Gagal mendapatkan ID transaksi yang baru disisipkan.");
      }

      transactionId = insertResponse.first['id'] as String; // Ambil ID transaksi dari database

      // 2. HAPUS BARIS INI JIKA POIN TIDAK INGIN BERKURANG
      // final newPoints = currentPoints - pointsToDeduct;
      // await supabase.from('members').update({'total_points': newPoints}).eq('id_user', user.id);

      // 3. Muat ulang poin saat ini dari database untuk update UI
      // Ini tetap diperlukan jika Anda ingin menampilkan poin terkini (meskipun tidak berubah karena penukaran)
      await fetchCurrentPoints();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reward \"$rewardTitle\" berhasil diklaim!",
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );

      // Tampilkan PopupPage hanya jika transactionId berhasil didapatkan
      if (transactionId != null && mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: true,
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation) {
              return PopupPage(
                title: rewardTitle,
                points: pointsToDeduct,
                transactionId: transactionId!, // Gunakan ID transaksi dari DB
              );
            },
            transitionsBuilder: (BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
                Widget child) {
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
          content: Text("Gagal mengklaim reward. Coba lagi nanti: $e",
              style: GoogleFonts.poppins()),
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
          .eq('status', 'setuju'); // Hanya ambil reward yang statusnya 'setuju'

      if (!mounted) return;
      if (response == null || response.isEmpty) {
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
      if (!mounted) return;
      setState(() {
        rewards = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Gagal memuat daftar reward: $e",
                  style: GoogleFonts.poppins())),
        );
      }
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
              colors: [Color(0xFF078603), Color(0xFF078603)], // Gradient hijau
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4), // Bayangan lembut
                  ),
                ],
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
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)))
                      : Text(
                          "$currentPoints",
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: const Color(
                                0xFF4CAF50), // Warna hijau untuk poin
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
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            "Tidak ada reward tersedia saat ini.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
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

  Widget _buildRewardCard(BuildContext context, String rewardId, String title,
      int points, String description) {
    // canRedeem sekarang bisa selalu true jika poin tidak berkurang,
    // atau Anda bisa menghapusnya jika validasi poin tidak diperlukan sama sekali.
    final bool canRedeem = true; // Set to true if points never deduct

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  // onPressed selalu aktif karena canRedeem selalu true
                  onPressed: () => showRedeemDialog(context, rewardId, title, points),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF078603), // Selalu hijau
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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

  void showRedeemDialog(
      BuildContext context, String rewardId, String title, int points) async {
    // Karena poin tidak berkurang, tidak perlu ada pengecekan "Poin Tidak Cukup" di sini.
    // Anda bisa langsung menampilkan dialog konfirmasi.

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Konfirmasi Klaim Reward",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Text(
            "Apakah Anda yakin ingin mengklaim reward \"$title\"?", // Hilangkan info poin jika tidak relevan
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
                await redeemReward(rewardId, title, points);
              },
              style: TextButton.styleFrom(
                foregroundColor:
                    const Color(0xFF4CAF50), // Warna hijau untuk tombol Klaim
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              child: const Text("Klaim"),
            ),
          ],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      },
    );
  }

  // Fungsi generateUniqueId tidak lagi digunakan untuk transactionId yang ditampilkan di PopupPage
  // karena ID akan diambil dari database. Namun, fungsi ini bisa tetap ada jika Anda menggunakannya
  // untuk keperluan lain di aplikasi Anda (misalnya, sebagai ID sementara sebelum disimpan ke DB).
  String generateUniqueId() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int random = Random().nextInt(900) + 100; // Angka acak 3 digit
    return "#$timestamp$random";
  }
}