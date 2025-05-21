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

  const PaymentPage(
      {super.key, required this.totalPrice, required this.getMemberId});

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
    print("PaymentPage initState() called");
    _fetchMemberId();
  }

  Future<void> _fetchMemberId() async {
    setState(() {
      _isMemberIdLoading = true;
    });
    print("PaymentPage calling getMemberId()");
    _memberId = await widget.getMemberId();
    setState(() {
      _isMemberIdLoading = false;
    });
    print("PaymentPage received memberId: $_memberId");
    if (_memberId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan ID pengguna.')),
        );
      }
    }
  }

  Future<void> createTransaction() async {
    if (_memberId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID Pengguna tidak tersedia.')),
        );
      }
      return;
    }

    String name = _nameController.text.trim();
    String tableNumber = _tableNumberController.text.trim();
    int totalPrice = widget.totalPrice;

    if (name.isEmpty || tableNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Silakan isi semua kolom'),
        ));
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });
    print("PaymentPage starting createTransaction()");

    if (!isCashSelected) {
      try {
        final response = await http.post(
          Uri.parse(
              'http://172.14.8.230:3000/create-transaction'), // Replace with your server URL
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'order_id':
                'ORDER-' + DateTime.now().millisecondsSinceEpoch.toString(),
            'gross_amount': totalPrice,
            'first_name': name,
            'email': 'example@mail.com', // Replace with user data
            'phone': '08123456789', // Replace with user data
          }),
        );
        print(
            "PaymentPage received response from createTransaction(): ${response.statusCode} - ${response.body}");

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          String snapToken = data['snapToken'];
          print("PaymentPage received snapToken: $snapToken");

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MidtransWebViewPage(snapToken: snapToken),
            ),
          );
          print(
              "PaymentPage received result from MidtransWebViewPage: $result");

          if (result == true) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentSuccessPage(
                    memberId: _memberId!,
                    totalPrice: widget.totalPrice,
                    namaPelanggan: name,
                    nomorMeja: tableNumber,
                  ),
                ),
              );
            }
            print("PaymentPage navigating to PaymentSuccessPage");
          } else if (result == false) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pembayaran Gagal!'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        } else {
          throw Exception('Gagal membuat transaksi: ${response.body}');
        }
      } catch (error) {
        print("PaymentPage error during createTransaction(): $error");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Terjadi kesalahan: $error'),
          ));
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
        print("PaymentPage createTransaction() finished");
      }
    } else {
      // If Cash payment, directly go to PaymentSuccessPage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessPage(
              memberId: _memberId!,
              totalPrice: widget.totalPrice,
              namaPelanggan: name,
              nomorMeja: tableNumber,
            ),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      print(
          "PaymentPage directly navigating to PaymentSuccessPage for Cash payment");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("PaymentPage build() called");
    return Scaffold(
      backgroundColor: Colors.grey[50], // Background yang lebih lembut
      appBar: AppBar(
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600, // Lebih tebal
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1, // Sedikit shadow
        iconTheme: const IconThemeData(color: Colors.black87),
        shape: const RoundedRectangleBorder(
          // Sudut membulat
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Wrap the Padding with SingleChildScrollView to prevent overflow
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Masukkan Detail',
                    style: TextStyle(
                      fontSize: 18, // Ukuran font agak kecil
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800, // Warna teks lebih gelap
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                      _nameController, 'Nama Pelanggan', Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField(
                      _tableNumberController, 'Nomor Meja', Icons.table_chart),
                  const SizedBox(height: 30),
                  Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 18, // Ukuran font agak kecil
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildPaymentOption('Tunai', 'assets/icon_cash.png', true),
                  const SizedBox(height: 10),
                  _buildPaymentOption('QRIS', 'assets/icon_qris.png', false),
                  // Removed Spacer here as SingleChildScrollView handles the overflow
                  // Add a SizedBox for consistent spacing before the total
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Pembayaran:',
                          style: TextStyle(
                            fontSize: 14, // Ukuran font agak kecil
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        // Wrap the price Text with Expanded
                        Expanded(
                          child: Text(
                            formatter.format(widget.totalPrice),
                            textAlign: TextAlign.right, // Align text to the right
                            style: const TextStyle(
                              fontSize: 14, // Ukuran font agak kecil
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isMemberIdLoading
                          ? null
                          : createTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2, // Sedikit shadow
                        textStyle: const TextStyle(
                          // Style teks
                          color: Colors.white,
                          fontSize: 16, // Ukuran font agak kecil
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(
                        _isLoading || _isMemberIdLoading
                            ? 'Memproses...'
                            : 'Bayar Sekarang',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Added bottom space
                ],
              ),
            ),
          ),
          if (_isLoading || _isMemberIdLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String labelText, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Warna latar belakang putih
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // Perbaikan: 'BoxShadow'
            color: Colors.grey.withOpacity(0.2), // Shadow lebih halus
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14), // Ukuran font agak kecil
          prefixIcon: Icon(icon, color: Colors.green.shade700, size: 20), // Ukuran icon agak kecil
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 15), // Padding agak kecil
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isCashSelected == isCash ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isCashSelected == isCash
                  ? Colors.green
                  : Colors.grey.shade300,
              width: isCashSelected == isCash ? 2 : 1),
          boxShadow: [
            BoxShadow(
              // Perbaikan: 'BoxShadow'
              color: Colors.grey.withOpacity(0.2), // Shadow lebih halus
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(iconPath, width: 25, height: 25), // Ukuran icon agak kecil
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14, // Ukuran font agak kecil
                fontWeight: FontWeight.w600, // Lebih tebal
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(
              isCashSelected == isCash
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: isCashSelected == isCash
                  ? Colors.green
                  : Colors.grey.shade400,
              size: 20, // Ukuran icon agak kecil
            )
          ],
        ),
      ),
    );
  }
}

// --- MidtransWebViewPage Class ---
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
    print(
        "MidtransWebViewPage initState() called with snapToken: ${widget.snapToken}");

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            print('MidtransWebViewPage URL Loaded: $url');

            if (url.contains('finish') || url.contains('success')) {
              print('MidtransWebViewPage: Payment finished or succeeded');
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            } else if (url.contains('error') || url.contains('failed')) {
              print('MidtransWebViewPage: Payment error or failed');
              if (mounted) {
                Navigator.of(context).pop(false);
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://app.sandbox.midtrans.com/snap/v2/vtweb/${widget.snapToken}'));
  }

  @override
  Widget build(BuildContext context) {
    print("MidtransWebViewPage build() called");
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pembayaran",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

// --- PaymentSuccessPage Class ---
class PaymentSuccessPage extends StatefulWidget {
  final String memberId; // Pastikan ini tidak nullable
  final int totalPrice;
  final String namaPelanggan;
  final String nomorMeja;

  const PaymentSuccessPage({
    super.key,
    required this.memberId,
    required this.totalPrice,
    required this.namaPelanggan,
    required this.nomorMeja,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isProcessingOrder = false;

  @override
  void initState() {
    super.initState();
    print(
        "PaymentSuccessPage initState() called with memberId: ${widget.memberId}, totalPrice: ${widget.totalPrice}, name: ${widget.namaPelanggan}, table: ${widget.nomorMeja}");
    _controller = AnimationController(vsync: this);

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await _processOrderAndPoints();
      }
    });
  }

  Future<List<Map<String, dynamic>>?> _fetchCartItems() async {
    try {
      final supabase = Supabase.instance.client;
      print(
          'PaymentSuccessPage: Fetching cart items for user ID: ${widget.memberId}');
      final response = await supabase
          .from('keranjang')
          .select()
          .eq('user_id', widget.memberId);
      print('PaymentSuccessPage: Fetch cart items response: $response');
      if (response is List) {
        print('PaymentSuccessPage: Found ${response.length} items in cart.');
        return response.cast<Map<String, dynamic>>();
      } else {
        print(
            'PaymentSuccessPage: No cart items found or response is not a List.');
        return null;
      }
    } catch (error) {
      print('PaymentSuccessPage: Error fetching cart items: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil item keranjang: $error')),
        );
      }
      return null;
    }
  }

  Future<void> _processOrderAndPoints() async {
    if (_isProcessingOrder) return;
    setState(() {
      _isProcessingOrder = true;
    });
    print("PaymentSuccessPage: Starting _processOrderAndPoints()");

    try {
      // Fetch cart items
      final cartItems = await _fetchCartItems();
      if (cartItems != null && cartItems.isNotEmpty) {
        await _saveOrderHistory(cartItems);
        await _clearShoppingCart();
      } else {
        print('PaymentSuccessPage: No items to process in cart.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada item di keranjang.')),
          );
        }
      }

      // --- LOGIC TO ADD POINTS BASED ON USER LEVEL ---
      final supabase = Supabase.instance.client;
      final String orderId = const Uuid().v4();

      // 1. Get user level and affiliate_id from members
      // Perhatikan: Anda mengambil id_user_level dari tabel 'users',
      // tapi points dari 'members'
      final memberData = await supabase
          .from('members')
          .select(
              'total_points, affiliate_id') // affiliate_id here MUST store affiliates.id
          .eq('id', widget.memberId)
          .single();

      // Pastikan 'users' adalah tabel yang benar untuk id_user_level
      final int currentUserLevel = await supabase
          .from('users')
          .select('id_user_level')
          .eq('id_user', widget.memberId) // id_user harus match dengan memberId
          .single()
          .then((data) => data['id_user_level'] as int? ?? 1);

      int currentMemberTotalPoints = memberData['total_points'] as int? ?? 0;
      // This affiliateIdOfCurrentMember is expected to be the 'id' from the affiliates table
      final String? affiliateIdOfCurrentMember =
          memberData['affiliate_id'] as String?;

      // Poin yang diterima oleh *member yang melakukan pembelian*
      const int pointsForPurchasingMember = 10;

      // Update total_points untuk member yang melakukan pembelian
      await supabase.from('members').update({
        'total_points': currentMemberTotalPoints + pointsForPurchasingMember
      }).eq('id', widget.memberId);
      print(
          'PaymentSuccessPage: Berhasil memperbarui total poin member yang membeli.');

      // Log poin untuk member yang melakukan pembelian
      await supabase.from('member_points_log').insert({
        'member_id': widget.memberId,
        'points_earned': pointsForPurchasingMember,
        'description': 'Poin dari pembelian (ID Order: $orderId)',
        'created_at': DateTime.now().toIso8601String(),
        'order_id': orderId,
      });
      print(
          'PaymentSuccessPage: Berhasil menambahkan log poin untuk member yang membeli.');

      // Logic untuk menambahkan poin ke AFILIASI (jika ada dan user level 4)
      if (currentUserLevel == 4 && affiliateIdOfCurrentMember != null) {
        print(
            'PaymentSuccessPage: Member level 4, akan menambahkan poin ke afiliasi.');
        const int affiliatePoints = 90;

        try {
          // Ketika mencari atau memperbarui, kita akan menggunakan 'id' sebagai primary key.
          // Ini berarti affiliateIdOfCurrentMember sekarang adalah ID dari tabel affiliates.
          final affiliateData = await supabase
              .from('affiliates')
              .select('id, total_points') // Select 'id' as well
              .eq('id', affiliateIdOfCurrentMember) // Match against 'id' column
              .maybeSingle();

          int existingAffiliatePoints = 0;

          if (affiliateData == null) {
            // Ini adalah skenario di mana `members.affiliate_id` tidak valid
            // (tidak ada di `affiliates.id`).
            // Karena Anda ingin mempertahankan foreign key dan tidak membuat entri baru di sini,
            // kita akan me-log peringatan dan tidak melanjutkan penambahan poin afiliasi.
            print(
                'PaymentSuccessPage: ERROR: Affiliate with ID $affiliateIdOfCurrentMember from members.affiliate_id NOT FOUND in affiliates.id.');
            print(
                'PaymentSuccessPage: Please verify data consistency in members.affiliate_id and affiliates.id.');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Peringatan: Data afiliasi tidak konsisten. Poin afiliasi tidak ditambahkan.')),
              );
            }
            setState(() {
              _isProcessingOrder = false;
            }); // Stop loading
            return; // Hentikan proses poin afiliasi jika ID tidak ditemukan
          } else {
            // Afiliasi sudah ada, perbarui poinnya menggunakan 'id'
            existingAffiliatePoints =
                affiliateData['total_points'] as int? ?? 0;
            await supabase.from('affiliates').update({
              'total_points': existingAffiliatePoints + affiliatePoints
            }).eq(
                'id', affiliateIdOfCurrentMember); // Match against 'id' column
            print(
                'PaymentSuccessPage: Successfully updated total points for existing affiliate.');
          }

          // Tambahkan penundaan singkat (optional, tapi bisa membantu dengan latensi)
          await Future.delayed(const Duration(milliseconds: 500));

          // Setelah memastikan afiliasi ada dan poinnya diperbarui, baru tambahkan log.
          await supabase.from('affiliate_points_log').insert({
            'affiliate_id':
                affiliateIdOfCurrentMember, // Gunakan ID yang diambil dari members, yang diasumsikan valid
            'member_id': widget.memberId,
            'order_id': orderId,
            'points_earned': affiliatePoints,
            'description':
                'Poin referral dari pembelian member ${widget.namaPelanggan} (ID Order: $orderId)',
            'created_at': DateTime.now().toIso8601String(),
          });
          print(
              'PaymentSuccessPage: Berhasil menambahkan log poin untuk afiliasi ($affiliateIdOfCurrentMember).');
        } on PostgrestException catch (e) {
          print(
              'PaymentSuccessPage: PostgrestException during affiliate points processing: ${e.message}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error database afiliasi: ${e.message}')),
            );
          }
        } catch (e) {
          print(
              'PaymentSuccessPage: General error during affiliate points processing: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Terjadi kesalahan tidak terduga pada afiliasi: $e')),
            );
          }
        }
      } else {
        print(
            'PaymentSuccessPage: User level bukan 4 atau tidak memiliki afiliasi, tidak ada poin afiliasi yang ditambahkan.');
      }
    } catch (error) {
      print(
          'PaymentSuccessPage: Error during _processOrderAndPoints (outer catch): $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Terjadi kesalahan saat memproses pesanan dan poin: $error')),
        );
      }
    } finally {
      setState(() {
        _isProcessingOrder = false;
      });
      print("PaymentSuccessPage: _processOrderAndPoints() finished");
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          print(
              "PaymentSuccessPage: Returning to home after process completes");
        }
      });
    }
  }

  Future<void> _saveOrderHistory(List<Map<String, dynamic>> cartItems) async {
    try {
      final supabase = Supabase.instance.client;
      final String orderNo =
          'ORDER-' + DateTime.now().millisecondsSinceEpoch.toString();

      // === PERBAIKAN DI SINI: Tambahkan 'member_id' ===
      final response = await supabase.from('orderkasir_history').insert({
        'order_no': orderNo,
        'nomor_meja': widget.nomorMeja,
        'nama_pelanggan': widget.namaPelanggan,
        'catatan': '',
        'items': cartItems,
        'total_item': cartItems.length,
        'total_harga': widget.totalPrice,
        'created_at': DateTime.now().toIso8601String(),
        'member_id': widget.memberId, // <<< PASTIKAN INI ADA DAN MEMBER_ID TIDAK NULL
      }).select();

      print('PaymentSuccessPage: Save order history response: $response');
      if (response != null && response.isNotEmpty) {
        print(
            'PaymentSuccessPage: Successfully saved order to orderkasir_history: $response');
      } else {
        print(
            'PaymentSuccessPage: Failed to save order to orderkasir_history (empty response or null).');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan riwayat pesanan.')),
          );
        }
      }
    } on PostgrestException catch (e) {
      // Tambahkan PostgrestException catch
      print(
          'PaymentSuccessPage: PostgrestException saving order history: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error database riwayat pesanan: ${e.message}')),
        );
      }
    } catch (error) {
      print('PaymentSuccessPage: Error saving order: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Terjadi kesalahan saat menyimpan riwayat pesanan: $error')),
        );
      }
    }
  }

  Future<void> _clearShoppingCart() async {
    try {
      final supabase = Supabase.instance.client;
      print(
          'PaymentSuccessPage: Attempting to clear cart for user ID: ${widget.memberId}');
      final response = await supabase
          .from('keranjang')
          .delete()
          .eq('user_id', widget.memberId);
      print('PaymentSuccessPage: Delete cart response: $response');
      if (response == null) {
        // Supabase delete returns null on success if no rows were returned
        print('PaymentSuccessPage: Successfully cleared items from cart');
      } else {
        // If response is not null, it might indicate an error object or unexpected data
        print(
            'PaymentSuccessPage: Failed to clear cart: ${response.toString()}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus keranjang.')),
          );
        }
      }
    } on PostgrestException catch (e) {
      // Tambahkan PostgrestException catch
      print(
          'PaymentSuccessPage: PostgrestException clearing cart items: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error database keranjang: ${e.message}')),
        );
      }
    } catch (error) {
      print('PaymentSuccessPage: Error clearing cart items: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Terjadi kesalahan saat menghapus item keranjang: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("PaymentSuccessPage build() called");
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
              width: 200, // Ukuran animasi agak kecil
              height: 200, // Ukuran animasi agak kecil
              repeat: false,
            ),
            const SizedBox(height: 20), // Spasi agak kecil
            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                fontSize: 22, // Ukuran font agak kecil
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8), // Spasi agak kecil
            Text(
              'Terima kasih atas pesanan Anda, ${widget.namaPelanggan}!',
              style: TextStyle(
                fontSize: 16, // Ukuran font agak kecil
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20), // Spasi agak kecil
            _isProcessingOrder
                ? const Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      SizedBox(height: 8), // Spasi agak kecil
                      Text(
                        'Memproses pesanan dan poin...',
                        style: TextStyle(
                          fontSize: 14, // Ukuran font agak kecil
                          color: Colors.black54,
                        ),
                      ),
                    ],
                )
                : ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      print("PaymentSuccessPage: Back to Home button pressed");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
          ],
        ),
      ),
    );
  }
}