import 'package:flutter/material.dart';
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
  int serviceFee = 2000; // Biaya layanan tetap

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

  /// **🔹 Menghitung subtotal dari makanan & minuman**
  int _calculateSubtotal() {
    return cartItems.entries.fold(0, (sum, entry) {
      int price =
          widget.menu_makanan[entry.key] ?? widget.menu_minuman[entry.key] ?? 0;
      return sum + (price * entry.value);
    });
  }

  /// **🔹 Menghitung total harga**
  int _calculateTotalPrice() {
    return _calculateSubtotal() + serviceFee;
  }

  /// **🔹 Fungsi untuk checkout**
 void _checkout() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => PaymentPagee()),
  );
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
                                                color: Colors.green,
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
                                                color: Colors.green),
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

                        /// **Detail Pembayaran + Tombol Checkout**
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
                                    Text("Rp ${_calculateSubtotal()}")
                                  ]),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Biaya Layanan"),
                                    Text("Rp $serviceFee")
                                  ]),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Total"),
                                    Text("Rp ${_calculateTotalPrice()}")
                                  ]),

                              const SizedBox(height: 12),

                              /// **Tombol Checkout**
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      cartItems.isNotEmpty ? _checkout : null,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    backgroundColor: Colors.green,
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
