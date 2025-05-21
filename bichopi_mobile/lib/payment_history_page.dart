import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal dan mata uang

class PaymentHistoryPage extends StatefulWidget {
  final String memberId;

  const PaymentHistoryPage({Key? key, required this.memberId})
      : super(key: key);

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<Map<String, dynamic>> _paymentHistory = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    if (widget.memberId.isEmpty) {
      setState(() {
        _errorMessage =
            'ID member tidak valid. Tidak dapat memuat riwayat pembayaran.';
        _isLoading = false;
      });
      print('DEBUG: Member ID is empty. Cannot fetch payment history.');
      return;
    }

    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('orderkasir_history')
          .select('*')
          .eq('member_id', widget.memberId)
          .order('created_at', ascending: false);

      setState(() {
        _paymentHistory =
            response.map((item) => item as Map<String, dynamic>).toList();
        _isLoading = false;
      });

      print(
          'DEBUG: Successfully fetched ${_paymentHistory.length} payment history entries.');
    } on PostgrestException catch (e) {
      print('DEBUG: Supabase PostgrestException: ${e.message}');
      if (e.message.contains('column "member_id" does not exist')) {
        _errorMessage =
            'Kesalahan database: Kolom "member_id" tidak ditemukan. Hubungi dukungan.';
      } else if (e.message.contains('invalid input syntax for type uuid')) {
        _errorMessage =
            'Format ID member tidak valid. Pastikan ID member adalah UUID yang benar.';
      } else {
        _errorMessage = 'Gagal memuat riwayat: ${e.message}.';
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Unexpected error fetching payment history: $e');
      _errorMessage = 'Terjadi kesalahan tidak terduga: ${e.toString()}.';
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearPaymentHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Hapus Semua Riwayat?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.grey[900], // Darker title
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus semua riwayat pembayaran Anda? Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.poppins(
                fontSize: 14, color: Colors.grey[700]), // Clearer content
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                    color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400], // Red accent for delete
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                elevation: 3, // Slight elevation for the button
              ),
              child: Text(
                'Hapus',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      try {
        await Supabase.instance.client
            .from('orderkasir_history')
            .delete()
            .eq('member_id', widget.memberId);

        setState(() {
          _paymentHistory = []; // Clear local list
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Riwayat pembayaran berhasil dihapus!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating, // Modern snackbar look
            margin: const EdgeInsets.all(10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } on PostgrestException catch (e) {
        setState(() {
          _errorMessage = 'Gagal menghapus riwayat: ${e.message}.';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus riwayat: ${e.message}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan tidak terduga: ${e.toString()}.';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terjadi kesalahan: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Latar belakang off-white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.5, // Subtle shadow for depth
        title: Text(
          "Riwayat Pembayaran",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 19, // Slightly adjusted font size
            color: Colors.grey[850],
          ),
        ),
        centerTitle: true,
        iconTheme:
            IconThemeData(color: Colors.grey[700]), // Consistent icon color
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever,
                color: Colors.red[400], size: 26), // Larger and red icon
            onPressed: _paymentHistory.isEmpty ? null : _clearPaymentHistory,
            tooltip: 'Hapus Semua Riwayat',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green[700]!))) // Darker green for loader
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _paymentHistory.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0), // Generous padding
                      itemCount: _paymentHistory.length,
                      itemBuilder: (context, index) {
                        final history = _paymentHistory[index];
                        return _buildPaymentCard(history);
                      },
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Consistent padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied_outlined,
              color: Colors.red[400],
              size: 70, // Slightly larger icon
            ),
            const SizedBox(height: 20),
            Text(
              "Terjadi Kesalahan",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _fetchPaymentHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700], // Consistent primary green
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                elevation: 3,
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Consistent padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              color: Colors.grey[300],
              size: 90, // Slightly larger icon
            ),
            const SizedBox(height: 20),
            Text(
              "Tidak Ada Riwayat Pembayaran",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Transaksi Anda akan muncul di sini. Mulai berbelanja!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15.0), // More space between cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // More rounded corners
      ),
      elevation: 6, // More pronounced shadow
      shadowColor: Colors.black.withOpacity(0.08), // Softer, more spread shadow
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Generous internal padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order No: ${history['order_no'] ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 17, // Clearer order number
                      color: Colors.grey[900], // Darker for emphasis
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100], // Light green tag
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Selesai',
                    style: GoogleFonts.poppins(
                      color: Colors.green[700], // Darker green text
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            Divider(
                height: 20, // More space around divider
                thickness: 0.6,
                color: Colors.grey[200]),
            _buildInfoRow(
              icon: Icons.table_bar_outlined,
              label: 'Meja',
              value: history['nomor_meja']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Pelanggan',
              value: history['nama_pelanggan'] ?? 'N/A',
            ),
            const SizedBox(height: 15), // More space before total
            Text(
              'Total Pembayaran',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              currencyFormatter.format(history['total_harga'] ?? 0),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 22, // Larger total price
                color: Colors.green[700], // Prominent green
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Transaksi pada: ${history['created_at'] != null ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(history['created_at']).toLocal()) : 'N/A'}',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic),
              ),
            ),
            // Item details section
            if (history['items'] != null &&
                history['items'] is List &&
                (history['items'] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  Text(
                    'Detail Pesanan:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(history['items'] as List).map((item) {
                    return _buildItemRow(item);
                  }).toList(),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Text(
                  'Detail Pesanan: Tidak ada item yang tercatat.',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[500]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk baris informasi umum
  Widget _buildInfoRow(
      {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 4.0), // Consistent vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon,
              size: 18, color: Colors.green[400]), // Accent green for icons
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600, // Slightly bolder value
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget untuk baris detail item
  Widget _buildItemRow(Map<String, dynamic> item) {
    final itemName = item['item_name'] ?? 'N/A';
    final itemQuantity = item['quantity'] ?? 'N/A';
    final itemPrice = item['price'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 4.0, horizontal: 8.0), // Slightly more horizontal padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '$itemQuantity x $itemName',
              style: GoogleFonts.poppins(
                fontSize: 13, // Slightly larger font
                color: Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currencyFormatter.format(itemPrice),
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 13, // Slightly larger font
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
