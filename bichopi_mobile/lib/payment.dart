import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

class PaymentPage extends StatefulWidget {
  final int totalPrice;
  final Future<String?> Function() getMemberId;
  const PaymentPage({super.key, required this.totalPrice, required this.getMemberId});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isCashSelected = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tableNumberController = TextEditingController();
  bool _isLoading = false;
  String? _memberId;
  bool _isMemberIdLoading = false;

  @override
  void initState() {
    super.initState();
    print("PaymentPage initState() dipanggil");
    _fetchMemberId();
  }

  Future<void> _fetchMemberId() async {
    setState(() {
      _isMemberIdLoading = true;
    });
    print("PaymentPage memanggil getMemberId()");
    _memberId = await widget.getMemberId();
    setState(() {
      _isMemberIdLoading = false;
    });
    print("PaymentPage menerima memberId: $_memberId");
    if (_memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan ID pengguna.')),
      );
    }
  }

  Future<void> createTransaction() async {
    if (_memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID pengguna belum tersedia.')),
      );
      return;
    }

    String name = _nameController.text;
    String tableNumber = _tableNumberController.text;
    int totalPrice = widget.totalPrice;

    if (name.isEmpty || tableNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Harap isi semua kolom'),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });
    print("PaymentPage memulai createTransaction()");

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.20:3000/create-transaction'), // Ganti dengan URL server Anda
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': 'ORDER-' + DateTime.now().millisecondsSinceEpoch.toString(),
          'gross_amount': totalPrice,
          'first_name': name,
          'email': 'example@mail.com', // Ganti dengan data pengguna
          'phone': '08123456789', // Ganti dengan data pengguna
        }),
      );
      print("PaymentPage menerima response dari createTransaction(): ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String snapToken = data['snapToken'];
        print("PaymentPage menerima snapToken: $snapToken");

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MidtransWebViewPage(snapToken: snapToken),
          ),
        );
        print("PaymentPage menerima hasil dari MidtransWebViewPage: $result");

        if (result == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessPage(memberId: _memberId!, totalPrice: widget.totalPrice),
            ),
          );
          print("PaymentPage navigasi ke PaymentSuccessPage");
        } else if (result == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran Gagal!'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Gagal membuat transaksi: ${response.body}');
      }
    } catch (error) {
      print("PaymentPage error saat createTransaction(): $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: $error'),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
      print("PaymentPage createTransaction() selesai");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("PaymentPage build() dipanggil");
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
                  'Total Pembayaran: ${formatter.format(widget.totalPrice)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading || _isMemberIdLoading ? null : createTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _isLoading || _isMemberIdLoading ? 'Memproses...' : 'Bayar Sekarang',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
          if (_isLoading || _isMemberIdLoading) const Center(child: CircularProgressIndicator()),
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
    print("MidtransWebViewPage initState() dipanggil dengan snapToken: ${widget.snapToken}");

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            print('MidtransWebViewPage URL Loaded: $url');

            if (url.contains('finish') || url.contains('success')) {
              print('MidtransWebViewPage: Pembayaran selesai atau sukses');
              Navigator.of(context).pop(true);
            } else if (url.contains('error') || url.contains('failed')) {
              print('MidtransWebViewPage: Pembayaran error atau gagal');
              Navigator.of(context).pop(false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://app.sandbox.midtrans.com/snap/v2/vtweb/${widget.snapToken}'));
  }

  @override
  Widget build(BuildContext context) {
    print("MidtransWebViewPage build() dipanggil");
    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran")),
      body: WebViewWidget(controller: _controller),
    );
  }
}

class PaymentSuccessPage extends StatefulWidget {
  final String memberId;
  final int totalPrice;
  const PaymentSuccessPage({super.key, required this.memberId, required this.totalPrice});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isAddingPoints = false;

  @override
  void initState() {
    super.initState();
    print("PaymentSuccessPage initState() dipanggil dengan memberId: ${widget.memberId}, totalPrice: ${widget.totalPrice}");
    _controller = AnimationController(vsync: this);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _addPointsToMember();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            print("PaymentSuccessPage: Kembali ke beranda");
          }
        });
      }
    });
  }

  int _calculatePoints(int totalPrice) {
    print("PaymentSuccessPage: Poin yang dihitung (DIUBAH KE 10)");
    return 10;
  }

  Future<void> _addPointsToMember() async {
    if (_isAddingPoints) return;
    setState(() {
      _isAddingPoints = true;
    });
    print("PaymentSuccessPage: Memulai _addPointsToMember()");
    try {
      final supabase = Supabase.instance.client;
      final int pointsEarned = _calculatePoints(widget.totalPrice); // Sekarang selalu 10
      const uuid = Uuid();
      final String orderId = uuid.v4(); // Generate UUID v4

      final response = await supabase
          .from('member_points_log') // Ganti dengan nama tabel log poin Anda
          .insert({
        'member_id': widget.memberId,
        'points_earned': pointsEarned,
        'description': 'Poin ditambahkan setelah pembayaran berhasil untuk order $orderId',
        'created_at': DateTime.now().toIso8601String(),
        'order_id': orderId,
      }).select();

      print("PaymentSuccessPage: Response dari insert member_points_log: $response");

      if (response != null) {
        print('PaymentSuccessPage: Poin ($pointsEarned) berhasil ditambahkan ke log untuk member: ${widget.memberId} (Order ID: $orderId)');
      } else {
        print('PaymentSuccessPage: Gagal menambahkan poin ke log: ${response?.error?.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menambahkan poin: ${response?.error?.message}')),
          );
        }
      }
    } catch (error) {
      print('PaymentSuccessPage: Terjadi kesalahan saat menambahkan poin: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat menambahkan poin: $error')),
        );
      }
    } finally {
      setState(() {
        _isAddingPoints = false;
      });
      print("PaymentSuccessPage: _addPointsToMember() selesai");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("PaymentSuccessPage build() dipanggil");
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animasi.json',
              controller: _controller,
              onLoaded: (composition) {
                _controller
                  ..duration = composition.duration
                  ..forward();
              },
              width: 200,
              height: 200,
              repeat: false,
            ),
            const SizedBox(height: 20),
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                print("PaymentSuccessPage: Tombol Kembali ke Beranda ditekan");
              },
              child: const Text('Kembali ke Beranda'),
            )
          ],
        ),
      ),
    );
  }
}