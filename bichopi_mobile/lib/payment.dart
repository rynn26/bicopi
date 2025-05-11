import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isCashSelected = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tableNumberController = TextEditingController();

  Future<void> createTransaction() async {
    String name = _nameController.text;
    String tableNumber = _tableNumberController.text;

    if (name.isEmpty || tableNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Harap isi semua kolom'),
      ));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/create-transaction'), // ganti IP jika bukan emulator
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': 'ORDER-' + DateTime.now().millisecondsSinceEpoch.toString(),
          'gross_amount': 50000, // jumlah pembayaran
          'first_name': name,
          'email': 'example@mail.com',
          'phone': '08123456789',
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
        throw Exception('Gagal membuat transaksi');
      }
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: $error'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Masukan Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Pemesan',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _tableNumberController,
              decoration: InputDecoration(
                labelText: 'Nomor Meja',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Text('Metode Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildPaymentOption('Cash', 'assets/icon_cash.png', true),
            _buildPaymentOption('QRIS', 'assets/icon_qris.png', false),
            Spacer(),
            ElevatedButton(
              onPressed: createTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Bayar Sekarang',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
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
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
              color: isCashSelected == isCash ? Colors.green : Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Image.asset(iconPath, width: 24, height: 24),
            SizedBox(width: 10),
            Text(title),
            Spacer(),
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
      appBar: AppBar(title: Text("Pembayaran")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
