import 'dart:convert';
import 'package:coba3/cart_halaman.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class PaymentPage extends StatefulWidget {
  final int totalPrice; // Perhatikan perubahan tipe data menjadi int
  const PaymentPage({super.key, required this.totalPrice});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isCashSelected = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tableNumberController = TextEditingController();
  bool _isLoading = false;

  Future<void> createTransaction() async {
    String name = _nameController.text;
    String tableNumber = _tableNumberController.text;
    int totalPrice = widget.totalPrice; // Gunakan totalPrice dari widget

    if (name.isEmpty || tableNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Harap isi semua kolom'),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'http://172.14.5.67:3000/create-transaction'), // Ganti dengan URL backend Anda
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id':
              'ORDER-' + DateTime.now().millisecondsSinceEpoch.toString(),
          'gross_amount': totalPrice, // Gunakan totalPrice dari CartPage
          'first_name': name,
          'email': 'example@mail.com', // Ganti dengan email pengguna
          'phone': '08123456789', // Ganti dengan nomor telepon pengguna
          // Tambahkan informasi lain yang dibutuhkan backend
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String snapToken = data['snapToken'];

        // Arahkan ke halaman WebView
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MidtransWebViewPage(snapToken: snapToken),
          ),
        );
      } else {
        throw Exception('Gagal membuat transaksi: ${response.body}');
      }
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: $error'),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Masukan Data',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pemesan',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _tableNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Meja',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Metode Pembayaran',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildPaymentOption('Cash', 'assets/icon_cash.png', true),
                _buildPaymentOption('QRIS', 'assets/icon_qris.png', false),
                const Spacer(),
                Text(
                  'Total Pembayaran: ${formatter.format(widget.totalPrice)}', // Tampilkan total harga
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : createTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _isLoading ? 'Memproses...' : 'Bayar Sekarang',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, String iconPath, bool isCash) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isCashSelected = isCash;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
              color: isCashSelected == isCash ? Colors.green : Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Image.asset(iconPath, width: 24, height: 24),
            const SizedBox(width: 10),
            Text(title),
            const Spacer(),
            Icon(
              isCashSelected == isCash
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isCashSelected == isCash ? Colors.green : Colors.grey,
            )
          ],
        ),
      ),
    );
  }
}

class MidtransWebViewPage extends StatefulWidget {
  final String snapToken;
  const MidtransWebViewPage({super.key, required this.snapToken});

  @override
  State<MidtransWebViewPage> createState() => _MidtransWebViewPageState();
}

class _MidtransWebViewPageState extends State<MidtransWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
          'https://app.sandbox.midtrans.com/snap/v2/vtweb/${widget.snapToken}'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
