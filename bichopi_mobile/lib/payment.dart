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
              'http://192.168.1.18:3000/create-transaction'), // Replace with your server URL
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
                  const SizedBox(height: 25),
                  _buildPaymentOption('Virtual Account', 'assets/virtualacc.png', false),
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
                            textAlign:
                                TextAlign.right, // Align text to the right
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
          labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14), // Ukuran font agak kecil
          prefixIcon: Icon(icon,
              color: Colors.green.shade700, size: 20), // Ukuran icon agak kecil
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 15), // Padding agak kecil
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
            Image.asset(iconPath,
                width: 25, height: 25), // Ukuran icon agak kecil
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
// --- PaymentSuccessPage Class ---

class PaymentSuccessPage extends StatefulWidget {
  final String memberId; // Ini adalah ID dari auth.users.id
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
  // Variabel untuk menyimpan ID Primary Key (PK) dari tabel 'members'
  // Ini akan digunakan untuk foreign key di tabel lain.
  String? _actualMemberIdInMembersTable;

  @override
  void initState() {
    super.initState();
    print(
        "PaymentSuccessPage initState() called with memberId: ${widget.memberId}, totalPrice: ${widget.totalPrice}, name: ${widget.namaPelanggan}, table: ${widget.nomorMeja}");
    _controller = AnimationController(vsync: this);

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        // Panggil proses utama setelah animasi selesai
        await _processOrderAndPoints();
      }
    });
  }

  // --- Fungsi untuk mengambil item keranjang ---
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
      // Supabase's .select() returns a List<Map<String, dynamic>> if successful,
      // or throws an error. So we can check if it's empty.
      if (response != null && response is List) {
        print('PaymentSuccessPage: Found ${response.length} items in cart.');
        return response.cast<Map<String, dynamic>>();
      } else {
        print(
            'PaymentSuccessPage: No cart items found or response is not a List or is null.');
        return null;
      }
    } on PostgrestException catch (e) {
      print(
          'PaymentSuccessPage: PostgrestException fetching cart items: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Gagal mengambil item keranjang dari database: ${e.message}')),
        );
      }
      return null;
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

  // --- Fungsi utama untuk memproses pesanan dan poin ---
  Future<void> _processOrderAndPoints() async {
    if (_isProcessingOrder) return; // Mencegah proses berulang
    setState(() {
      _isProcessingOrder = true;
    });
    print("PaymentSuccessPage: Starting _processOrderAndPoints()");

    try {
      // 1. Ambil item keranjang terlebih dahulu
      final cartItems = await _fetchCartItems();
      if (cartItems == null || cartItems.isEmpty) {
        print(
            'PaymentSuccessPage: Tidak ada item untuk diproses di keranjang.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada item di keranjang.')),
          );
        }
        return; // Keluar jika tidak ada item keranjang
      }

      final supabase = Supabase.instance.client;
      final String orderId = const Uuid().v4(); // Generate UUID untuk order ID

      // 2. Pastikan member ada di tabel 'members'
      // Ini sangat penting untuk memenuhi foreign key constraint
      Map<String, dynamic>? memberRecord; // Change to Map<String, dynamic>?
      try {
        memberRecord = await supabase
            .from('members')
            .select(
                'id, total_points, affiliate_id') // Pilih 'id' (PK tabel members)
            .eq('id_user',
                widget.memberId) // Menggunakan id_user dari auth.users.id
            .maybeSingle(); // maybeSingle returns null if no record, or a map if one record
      } on PostgrestException catch (e) {
        print(
            'PaymentSuccessPage: PostgrestException saat mencari member: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Error database saat mencari member: ${e.message}')),
          );
        }
        return;
      } catch (e) {
        print('PaymentSuccessPage: Error umum saat mencari member: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Terjadi kesalahan saat mencari member: $e')),
          );
        }
        return;
      }

      // Set _actualMemberIdInMembersTable berdasarkan hasil pencarian/pembuatan member
      if (memberRecord == null) {
        // Jika tidak ada catatan member, buat satu
        print(
            'PaymentSuccessPage: Tidak ada catatan member ditemukan untuk ID pengguna: ${widget.memberId}. Membuat yang baru.');
        try {
          final List<Map<String, dynamic>> newMemberResponse = await supabase
              .from('members')
              .insert({
            'id_user': widget.memberId, // Tautkan ke auth.users.id
            'total_points': 0,
          }).select(
                  'id'); // Ambil 'id' (PK) dari member yang baru dibuat. select() returns a list.

          if (newMemberResponse.isNotEmpty) {
            _actualMemberIdInMembersTable =
                newMemberResponse.first['id'] as String; // Update state
            print(
                'PaymentSuccessPage: Member baru dibuat dengan ID: $_actualMemberIdInMembersTable');
          } else {
            print(
                'PaymentSuccessPage: Gagal membuat member baru, respons kosong.');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Gagal membuat catatan member baru.')),
              );
            }
            return;
          }
        } on PostgrestException catch (e) {
          print(
              'PaymentSuccessPage: PostgrestException saat membuat member baru: ${e.message}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Error database saat membuat member: ${e.message}')),
            );
          }
          return;
        } catch (e) {
          print('PaymentSuccessPage: Error umum saat membuat member baru: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Terjadi kesalahan saat membuat member: $e')),
            );
          }
          return;
        }
      } else {
        _actualMemberIdInMembersTable =
            memberRecord['id'] as String; // Update state dengan PK yang ada
        print(
            'PaymentSuccessPage: Member ditemukan dengan ID: $_actualMemberIdInMembersTable');
      }

      // Panggil _saveOrderHistory SETELAH _actualMemberIdInMembersTable terisi
      await _saveOrderHistory(
          cartItems, orderId); // Pass orderId to _saveOrderHistory
      await _clearShoppingCart();

      // 3. Lanjutkan dengan logika poin menggunakan _actualMemberIdInMembersTable
      int currentMemberTotalPoints = memberRecord?['total_points'] as int? ?? 0;
      final String? affiliateIdOfCurrentMember =
          memberRecord?['affiliate_id'] as String?;

      // Dapatkan level pengguna dari tabel 'users' (asumsi tabel kustom Anda)
      int currentUserLevel = 1; // Default
      try {
        final userLevelData = await supabase
            .from('users') // Nama tabel yang menyimpan level pengguna
            .select('id_user_level')
            .eq(
                'id_user',
                widget
                    .memberId) // Menggunakan 'id_user' sebagai kolom untuk mencocokkan widget.memberId
            .maybeSingle();

        if (userLevelData != null) {
          currentUserLevel = userLevelData['id_user_level'] as int? ?? 1;
          print('PaymentSuccessPage: User level: $currentUserLevel');
        } else {
          print(
              'PaymentSuccessPage: User level data not found for ${widget.memberId}. Using default level 1.');
        }
      } on PostgrestException catch (e) {
        print(
            'PaymentSuccessPage: PostgrestException saat mengambil level pengguna: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error database saat mengambil level pengguna: ${e.message}')),
          );
        }
        // Jangan return, biarkan proses berlanjut dengan level default
      } catch (e) {
        print(
            'PaymentSuccessPage: Error umum saat mengambil level pengguna: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Terjadi kesalahan saat mengambil level pengguna: $e')),
          );
        }
        // Jangan return, biarkan proses berlanjut dengan level default
      }

      // --- LOGIKA POIN ---
      int pointsForPurchasingMember;
      if (affiliateIdOfCurrentMember == null ||
          affiliateIdOfCurrentMember.isEmpty) {
        pointsForPurchasingMember = 100;
        print(
            'PaymentSuccessPage: Member tidak memiliki afiliasi. Member mendapatkan $pointsForPurchasingMember poin.');
      } else {
        pointsForPurchasingMember =
            0; // Member with affiliate gets 0 points from their own purchase directly
        print(
            'PaymentSuccessPage: Member memiliki afiliasi. Member mendapatkan $pointsForPurchasingMember poin langsung.');
      }

      // Update total_points untuk member yang melakukan pembelian
      if (_actualMemberIdInMembersTable != null) {
        await supabase.from('members').update({
          'total_points': currentMemberTotalPoints + pointsForPurchasingMember
        }).eq('id',
            _actualMemberIdInMembersTable!); // Menggunakan PK yang sebenarnya dari 'members'
        print(
            'PaymentSuccessPage: Berhasil memperbarui total poin member yang membeli.');

        // Log poin untuk member yang melakukan pembelian
        await supabase.from('member_points_log').insert({
          'member_id':
              _actualMemberIdInMembersTable, // Menggunakan PK yang sebenarnya dari 'members'
          'points_earned': pointsForPurchasingMember,
          'description': 'Poin dari pembelian (ID Pesanan: $orderId)',
          'created_at': DateTime.now().toIso8601String(),
          'order_id': orderId,
        });
        print(
            'PaymentSuccessPage: Berhasil menambahkan log poin untuk member yang membeli.');
      } else {
        print(
            'PaymentSuccessPage: _actualMemberIdInMembersTable is null, cannot update member points or log points.');
      }

      // Logika untuk menambahkan poin ke AFILIASI (jika ada dan level pengguna BUKAN 1)
      if (currentUserLevel != 1 &&
          affiliateIdOfCurrentMember != null &&
          affiliateIdOfCurrentMember.isNotEmpty) {
        print(
            'PaymentSuccessPage: Member level BUKAN 1 dan memiliki afiliasi, akan menambahkan poin ke afiliasi.');
        const int affiliatePoints = 100;

        try {
          final affiliateData = await supabase
              .from('affiliates')
              .select('id, total_points')
              .eq('id', affiliateIdOfCurrentMember)
              .maybeSingle();

          int existingAffiliatePoints = 0;

          if (affiliateData == null) {
            print(
                'PaymentSuccessPage: ERROR: Afiliasi dengan ID $affiliateIdOfCurrentMember dari members.affiliate_id TIDAK DITEMUKAN di affiliates.id.');
            print(
                'PaymentSuccessPage: Harap verifikasi konsistensi data di members.affiliate_id dan affiliates.id.');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Peringatan: Data afiliasi tidak konsisten. Poin afiliasi tidak ditambahkan.')),
              );
            }
          } else {
            existingAffiliatePoints =
                affiliateData['total_points'] as int? ?? 0;
            await supabase.from('affiliates').update({
              'total_points': existingAffiliatePoints + affiliatePoints
            }).eq('id', affiliateIdOfCurrentMember);
            print(
                'PaymentSuccessPage: Berhasil memperbarui total poin untuk afiliasi yang ada.');

            await Future.delayed(
                const Duration(milliseconds: 500)); // Penundaan untuk latensi

            await supabase.from('affiliate_points_log').insert({
              'affiliate_id': affiliateIdOfCurrentMember,
              'member_id':
                  _actualMemberIdInMembersTable, // Menggunakan PK yang sebenarnya dari 'members'
              'order_id': orderId,
              'points_earned': affiliatePoints,
              'description':
                  'Poin rujukan dari pembelian member ${widget.namaPelanggan} (ID Pesanan: $orderId)',
              'created_at': DateTime.now().toIso8601String(),
            });
            print(
                'PaymentSuccessPage: Berhasil menambahkan log poin untuk afiliasi ($affiliateIdOfCurrentMember).');
          }
        } on PostgrestException catch (e) {
          print(
              'PaymentSuccessPage: PostgrestException selama pemrosesan poin afiliasi: ${e.message}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error database afiliasi: ${e.message}')),
            );
          }
        } catch (e) {
          print(
              'PaymentSuccessPage: Error umum selama pemrosesan poin afiliasi: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Terjadi kesalahan tak terduga pada afiliasi: $e')),
            );
          }
        }
      } else {
        print(
            'PaymentSuccessPage: Level pengguna adalah 1 atau tidak memiliki afiliasi yang valid, tidak ada poin afiliasi yang ditambahkan.');
      }
    } catch (error) {
      print(
          'PaymentSuccessPage: Error selama _processOrderAndPoints (outer catch): $error');
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
      print("PaymentSuccessPage: _processOrderAndPoints() selesai");
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          // Navigasi kembali ke halaman utama (root) dari aplikasi
          Navigator.of(context).popUntil((route) => route.isFirst);
          print(
              "PaymentSuccessPage: Kembali ke beranda setelah proses selesai");
        }
      });
    }
  }

  // --- Fungsi untuk menyimpan riwayat pesanan ---
  // Added orderId parameter
  Future<void> _saveOrderHistory(
      List<Map<String, dynamic>> cartItems, String orderId) async {
    try {
      final supabase = Supabase.instance.client;
      // Using the provided orderId for consistency across logs and history
      final String orderNo = orderId; // Or 'ORDER-' + orderId if you prefer

      // PENTING: Pastikan _actualMemberIdInMembersTable sudah diisi sebelum memanggil fungsi ini.
      // Ini dijamin karena _saveOrderHistory dipanggil setelah logika member di _processOrderAndPoints.
      if (_actualMemberIdInMembersTable == null) {
        print(
            'PaymentSuccessPage: Error: _actualMemberIdInMembersTable is NULL when saving order history. Order will not be saved.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'ID Anggota untuk riwayat pesanan tidak ditemukan. Pesanan tidak disimpan.')),
          );
        }
        return; // Hentikan proses jika ID null
      }

      final response = await supabase.from('orderkasir_history').insert({
        'order_no': orderNo, // Use the generated orderId
        'nomor_meja': widget.nomorMeja,
        'nama_pelanggan': widget.namaPelanggan,
        'catatan': '', // Assuming 'catatan' is an empty string for now
        'items': cartItems, // This expects a JSONB column in Supabase
        'total_item': cartItems.length,
        'total_harga': widget.totalPrice,
        'created_at': DateTime.now().toIso8601String(),
        'member_id':
            _actualMemberIdInMembersTable, // Foreign key to 'members' table
      }).select(); // Use .select() to get the inserted data back

      print('PaymentSuccessPage: Save order history response: $response');
      if (response != null && response.isNotEmpty) {
        print(
            'PaymentSuccessPage: Successfully saved order to orderkasir_history: ${response.first}'); // Log the first inserted record
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
      print(
          'PaymentSuccessPage: PostgrestException saving order history: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error database riwayat pesanan: ${e.message}')),
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

  // --- Fungsi untuk mengosongkan keranjang belanja ---
  Future<void> _clearShoppingCart() async {
    try {
      final supabase = Supabase.instance.client;
      print(
          'PaymentSuccessPage: Attempting to clear cart for user ID: ${widget.memberId}');
      // Supabase's delete() returns null on success, or throws PostgrestException on error.
      await supabase.from('keranjang').delete().eq('user_id', widget.memberId);

      print('PaymentSuccessPage: Successfully cleared items from cart');
    } on PostgrestException catch (e) {
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
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animasi.json', // Pastikan path ini benar
                  controller: _controller,
                  onLoaded: (composition) {
                    _controller
                      ..duration = composition.duration
                      ..forward();
                  },
                ),
                const Text(
                  'Pembayaran Berhasil!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Terima kasih atas pesanan Anda, ${widget.namaPelanggan}!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Total Pembayaran',
                          formatter.format(widget.totalPrice)),
                      _buildInfoRow('Nama Pelanggan', widget.namaPelanggan),
                      _buildInfoRow('Nomor Meja', widget.nomorMeja),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                if (_isProcessingOrder)
                  Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Memproses pesanan dan poin...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (_isProcessingOrder)
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
