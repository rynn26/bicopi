import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'payment.dart';

final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class CartPage extends StatefulWidget {
  final Map<String, int> cartItems;

  const CartPage({
    super.key,
    required this.cartItems,
    required Map<String, int> menu_makanan,
    required Map menu_snack,
    required Map menu_paket,
    required Map<String, int> menu_minuman,
  });

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Map<String, int> cartItems;
  Map<String, int> semuaHargaMenu = {};
  int serviceFee = 2000;
  String? userId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    cartItems = Map.from(widget.cartItems);
    final user = Supabase.instance.client.auth.currentUser;
    userId = user?.id;
    _loadCartFromSupabase();
    _loadHargaMenu();
  }

  Future<void> _loadHargaMenu() async {
    final response = await Supabase.instance.client
        .from('menu')
        .select('nama_menu, harga_menu');

    if (response != null) {
      setState(() {
        semuaHargaMenu = {
          for (var item in response)
            item['nama_menu'].toString(): int.tryParse(item['harga_menu'].toString()) ?? 0,
        };
      });
    }
  }

  Future<void> _loadCartFromSupabase() async {
    final supabase = Supabase.instance.client;
    if (userId == null) return;

    try {
      final response = await supabase
          .from('keranjang')
          .select()
          .eq('user_id', userId);

      for (var item in response) {
        String name = item['item_name'];
        int quantity = item['quantity'];
        cartItems[name] = quantity;
      }
      setState(() {});
    } catch (e) {
      print('Gagal memuat data keranjang: $e');
    }
  }

  Future<void> _updateQuantityInSupabase(String itemName, int quantity) async {
    final supabase = Supabase.instance.client;
    if (userId == null) return;

    final price = semuaHargaMenu[itemName] ?? 0;
    final now = DateTime.now().toIso8601String();

    if (quantity > 0) {
      await supabase.from('keranjang').upsert({
  'user_id': userId,
  'item_name': itemName,
  'quantity': quantity,
  'price': price,
  'created_at': now.toIso8601String(),
  'updated_at': now.toIso8601String(),
}, onConflict: 'user_id,item_name');

    } else {
      await supabase
          .from('keranjang')
          .delete()
          .eq('user_id', userId)
          .eq('item_name', itemName);
    }
  }

  void _increaseQuantity(String itemName) async {
    if (!cartItems.containsKey(itemName)) return;
    setState(() {
      cartItems[itemName] = cartItems[itemName]! + 1;
    });
    await _updateQuantityInSupabase(itemName, cartItems[itemName]!);
  }

  void _decreaseQuantity(String itemName) async {
    if (!cartItems.containsKey(itemName)) return;
    final currentQty = cartItems[itemName]!;
    if (currentQty > 1) {
      setState(() {
        cartItems[itemName] = currentQty - 1;
      });
      await _updateQuantityInSupabase(itemName, currentQty - 1);
    } else {
      setState(() {
        cartItems.remove(itemName);
      });
      await _updateQuantityInSupabase(itemName, 0);
    }
  }

  int _calculateSubtotal() {
    return cartItems.entries.fold(0, (sum, entry) {
      int price = semuaHargaMenu[entry.key] ?? 0;
      return sum + (price * entry.value);
    });
  }

  int _calculateTotalPrice() {
    return _calculateSubtotal() + serviceFee;
  }

  Future<void> _saveCartToSupabase() async {
    final supabase = Supabase.instance.client;
    final now = DateTime.now();

    if (userId == null) return;

    try {
      for (var entry in cartItems.entries) {
        final itemName = entry.key;
        final quantity = entry.value;
        final price = semuaHargaMenu[itemName] ?? 0;

        if (quantity > 0) {
          await supabase.from('keranjang').upsert({
            'user_id': userId,
            'item_name': itemName,
            'quantity': quantity,
            'price': price,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
        }
      }
    } catch (e) {
      print('Error saat menyimpan ke Supabase: $e');
    }
  }

  void _checkout(BuildContext context) async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Checkout"),
        content: const Text("Apakah Anda yakin ingin melanjutkan ke pembayaran?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Lanjutkan"),
          ),
        ],
      ),
    );

    if (shouldProceed == true) {
      setState(() => isLoading = true);
      try {
        await _saveCartToSupabase();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PaymentPage()),
        );
      } catch (e) {
        print("Error saat checkout: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal melakukan checkout.")),
        );
      } finally {
        setState(() => isLoading = false);
      }
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              String itemName = cartItems.keys.elementAt(index);
                              int quantity = cartItems[itemName]!;
                              int itemPrice = semuaHargaMenu[itemName] ?? 0;

                              return CartItemCard(
                                itemName: itemName,
                                quantity: quantity,
                                itemPrice: itemPrice,
                                onIncrease: () => _increaseQuantity(itemName),
                                onDecrease: () => _decreaseQuantity(itemName),
                              );
                            },
                          ),
                        ),
                        PaymentSummaryCard(
                          subtotal: _calculateSubtotal(),
                          serviceFee: serviceFee,
                          total: _calculateTotalPrice(),
                          isLoading: isLoading,
                          onCheckout: () => _checkout(context),
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

extension on String {
  toIso8601String() {}
}

// Komponen UI

class CartItemCard extends StatelessWidget {
  final String itemName;
  final int quantity;
  final int itemPrice;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const CartItemCard({
    super.key,
    required this.itemName,
    required this.quantity,
    required this.itemPrice,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = itemPrice * quantity;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(itemName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("${formatter.format(itemPrice)} x $quantity", style: const TextStyle(fontSize: 14)),
                  Text("Total: ${formatter.format(totalPrice)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF078603))),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: onDecrease,
                ),
                Text("$quantity"),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF078603)),
                  onPressed: onIncrease,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentSummaryCard extends StatelessWidget {
  final int subtotal;
  final int serviceFee;
  final int total;
  final bool isLoading;
  final VoidCallback onCheckout;

  const PaymentSummaryCard({
    super.key,
    required this.subtotal,
    required this.serviceFee,
    required this.total,
    required this.isLoading,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Detail Pembayaran", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Subtotal"),
            Text(formatter.format(subtotal)),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Biaya Layanan"),
            Text(formatter.format(serviceFee)),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Total"),
            Text(formatter.format(total)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onCheckout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF078603),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Checkout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Keranjang", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Bichopi, Indonesia", style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}