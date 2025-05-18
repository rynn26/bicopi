import 'dart:math';
import 'package:coba3/reedem_up.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
 // Import PopupPage

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
    fetchCurrentPoints();
    fetchRewards();
  }

  Future<void> fetchCurrentPoints() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User belum login.");
      }

      final response = await supabase
          .from('member_points_log')
          .select('points_earned')
          .eq('member_id', user.id);

      if (response == null || response.isEmpty) {
        setState(() {
          currentPoints = 0;
        });
        return;
      }

      int total = 0;
      for (final row in response) {
        total += row['points_earned'] as int;
      }

      setState(() {
        currentPoints = total;
      });
    } catch (e) {
      print("Error mengambil poin: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
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
                  onPressed: () => showRedeemDialog(context, rewardId, title, points),
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

  void showRedeemDialog(BuildContext context, String rewardId, String title, int points) async {
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

    final hasRedeemed = await hasRedeemedRecently(rewardId);
    if (hasRedeemed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Anda telah mengklaim reward ini. Anda dapat mengklaimnya lagi setelah 7 hari.",
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
              onPressed: () async {
                Navigator.pop(context);

                await deductPoints(points, title, rewardId);

                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    barrierDismissible: true,
                    transitionDuration: const Duration(milliseconds: 300),
                    pageBuilder: (BuildContext context, Animation<double> animation,
                        Animation<double> secondaryAnimation) {
                      return PopupPage(
                        title: title,
                        points: points,
                        transactionId: transactionId,
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

  String generateUniqueId() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int random = Random().nextInt(900) + 100;
    return "#$timestamp$random";
  }
}