import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PopupPage extends StatelessWidget {
  final String title;
  final int points;
  final String transactionId;

  const PopupPage({
    super.key,
    required this.title,
    required this.points,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async =>
          false, // Mencegah menutup dialog dengan tombol kembali fisik selama animasi
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(
                parent: ModalRoute.of(context)!.animation!,
                curve: Curves.easeInOutCubic,
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(
                  parent: ModalRoute.of(context)!.animation!,
                  curve: Curves.easeInOutCubic,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Icon(Icons.receipt_long,
                          size: 60, color: Colors.green[400]),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Tanda Terima Penukaran",
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(thickness: 1, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      "ID Penukaran",
                      style: GoogleFonts.nunitoSans(
                          fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      transactionId,
                      style: GoogleFonts.nunitoSans(
                          color: Colors.black87, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Penukaran Point",
                      style: GoogleFonts.nunitoSans(
                          fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.sync, size: 20, color: Colors.green[400]),
                        const SizedBox(width: 8),
                        Text("$points POIN",
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                        ),
                        child: Text(
                          "Close",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
