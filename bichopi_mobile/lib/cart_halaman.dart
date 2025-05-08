import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'payment.dart';

class CartPage extends StatefulWidget {
  final Map<String, int> cartItems;
  final Map<String, int> menu_makanan;
  final Map<String, int> menu_minuman;

  const CartPage({
    super.key,
    required this.cartItems,
    required this.menu_makanan,
    required this.menu_minuman,
  });

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Map<String, int> cartItems;
  int serviceFee = 2000;

  @override
  void initState() {
    super.initState();
    cartItems = Map.from(widget.cartItems);
  }

  void _increaseQuantity(String itemName) {
    setState(() {
      cartItems[itemName] = (cartItems[itemName] ?? 1) + 1;
    });
  }

  void _decreaseQuantity(String itemName) {
    setState(() {
      if (cartItems[itemName] != null && cartItems[itemName]! > 1) {
        cartItems[itemName] = cartItems[itemName]! - 1;
      } else {
        cartItems.remove(itemName);
      }
    });
  }

  int _calculateSubtotal() {
    return cartItems.entries.fold(0, (sum, entry) {
      int price =
          widget.menu_makanan[entry.key] ?? widget.menu_minuman[entry.key] ?? 0;
      return sum + (price * entry.value);
    });
  }

  int _calculateTotalPrice() {
    return _calculateSubtotal() + serviceFee;
  }

  /// ✅ Simpan ke tabel 'keranjang' Supabase
  Future<void> _saveCartToSupabase() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User belum login')),
      );
      return;
    }

    final now = DateTime.now();

    for (var entry in cartItems.entries) {
      final itemName = entry.key;
      final quantity = entry.value;
      final price = widget.menu_makanan[itemName] ??
          widget.menu_minuman[itemName] ??
          0;

      await supabase.from('keranjang').insert({
        'user_id': userId,
        'item_name': itemName,
        'quantity': quantity,
        'price': price,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }
  }

  void _checkout() async {
    // Tampilkan dialog konfirmasi sebelum navigasi
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Checkout"),
        content: const Text("Apakah Anda yakin ingin melanjutkan ke pembayaran?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Tidak
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Ya
            child: const Text("Lanjutkan"),
          ),
        ],
      ),
    );

    if (shouldProceed == true) {
      await _saveCartToSupabase();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaymentPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const CustomAppBar(),
          Expanded(
            child: cartItems.isEmpty
                ? const Center(
                    child: Text(
                      "Keranjang masih kosong",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              String itemName = cartItems.keys.elementAt(index);
                              int quantity = cartItems[itemName]!;
                              int itemPrice = widget.menu_makanan[itemName] ??
                                  widget.menu_minuman[itemName] ??
                                  0;
                              int totalPrice = itemPrice * quantity;

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              itemName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "Rp $itemPrice x $quantity",
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              "Total: Rp $totalPrice",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF078603),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle_outline,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _decreaseQuantity(itemName),
                                          ),
                                          Text("$quantity"),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.add_circle_outline,
                                                color: Color(0xFF078603)),
                                            onPressed: () =>
                                                _increaseQuantity(itemName),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        /// Detail pembayaran + tombol
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Detail Pembayaran",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Subtotal"),
                                    Text("Rp ${_calculateSubtotal()}"),
                                  ]),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Biaya Layanan"),
                                    Text("Rp $serviceFee"),
                                  ]),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Total"),
                                    Text("Rp ${_calculateTotalPrice()}"),
                                  ]),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      cartItems.isNotEmpty ? _checkout : null,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    backgroundColor: const Color(0xFF078603),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    "Checkout",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF078603),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Keranjang",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Bichopi, Indonesia",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}