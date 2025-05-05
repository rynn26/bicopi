import 'package:flutter/material.dart';
import 'cart_halaman.dart';

class PaketMenuPage extends StatefulWidget {
  final String categoryName;

  const PaketMenuPage({super.key, required this.categoryName});

  @override
  State<PaketMenuPage> createState() => _PaketMenuState();
}


class _PaketMenuState extends State<PaketMenuPage> {
  List<Map<String, dynamic>> menuItems = [
     {
      "name": "Ayam Geprek",
      "category": "Makanan",
      "description": "Pedas dan bergizi",
      "price": 15000,
      "image": "assets/ayamgeprek.png"
    },
    {
      "name": "Bakso",
      "category": "Makanan",
      "description": "Tanpa Tepung",
      "price": 14000,
      "image": "assets/bakso.png"
    },
    {
      "name": "Mie Goreng",
      "category": "Makanan",
      "description": "Cocok untuk akhir bulan",
      "price": 13000,
      "image": "assets/mie_goreng.png"
    },
    {
      "name": "Nasi Goreng",
      "category": "Makanan",
      "description": "Pedas Nampol",
      "price": 14000,
      "image": "assets/nasi_goreng.png"
    },
  ];
  Map<String, int> cartQuantities = {}; // Menyimpan jumlah item dalam keranjang

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      // Jika item sudah ada, tambahkan jumlahnya
      if (cartQuantities.containsKey(item["name"])) {
        cartQuantities[item["name"]] = cartQuantities[item["name"]]! + 1;
      } else {
        cartQuantities[item["name"]] = 1;
      }
    });

    _showAddToCartDialog(context, item); // ✅ Tampilkan modal dengan jumlah terbaru
  }
 void _showAddToCartDialog(BuildContext context, Map<String, dynamic> item) {
    int quantity = cartQuantities[item["name"]] ?? 1;
    int price = item["price"]; // ✅ Harga sudah dalam bentuk int
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (BuildContext context) {
      return GestureDetector(
               onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartPage(
                  cartItems: cartQuantities,
                  menu_makanan: {for (var item in menuItems) item["name"]: item["price"]}, // ✅ Kirim data makanan ke CartPage
                  menu_minuman: {}, // Kosong karena hanya makanan
                ),
              ),
            );
          },
        behavior: HitTestBehavior.opaque, // Memastikan GestureDetector menangkap tap di seluruh area modal
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF078603), // Warna hijau
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.white),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Jumlah Pesanan: $quantity",
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                          Text(
                            item["name"],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                        "Rp ${price * quantity}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF078603), // Warna hijau
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Menu Paket",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Bichopi, Indonesia",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    item["image"],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                ElevatedButton(
                                  onPressed: () => _addToCart(item),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(
                                          color: Color(0xFF078603)), // Warna hijau
                                    ),
                                  ),
                                  child: const Text(
                                    "Tambah",
                                    style: TextStyle(color: Color(0xFF078603)), // Warna hijau
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item["name"],
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    item["category"],
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(item["description"]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 12,
                        child: Text(
                          "Rp ${item["price"]}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
