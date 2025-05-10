import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_halaman.dart';

class PaketMenuPage extends StatefulWidget {
  final int categoryId = 4; // Anggap kategori untuk Paket adalah 4

  const PaketMenuPage(
      {super.key, required String categoryName, required int categoryId});

  @override
  State<PaketMenuPage> createState() => _PaketMenuPageState();
}

class _PaketMenuPageState extends State<PaketMenuPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> menuItems = [];
  Map<String, int> cartQuantities = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPaketItems();
  }

  Future<void> fetchPaketItems() async {
    try {
      final response = await supabase
          .from('menu')
          .select('nama_menu, foto_menu, deskripsi_menu, harga_menu')
          .eq('id_kategori_menu',
              widget.categoryId); // Mengambil kategori Paket

      setState(() {
        menuItems = List<Map<String, dynamic>>.from(response);
        menuItems = response.map<Map<String, dynamic>>((item) {
          return {
            "nama_menu": item["nama_menu"],
            "foto_menu": item["foto_menu"],
            "deskripsi_menu": item["deskripsi_menu"],
            "harga_menu": (item["harga_menu"] is double)
                ? item["harga_menu"].toInt()
                : (item["harga_menu"] ?? 0),
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Gagal fetch data paket: $e');
      setState(() => isLoading = false);
    }
  }

  int _parseHarga(dynamic harga) {
    try {
      if (harga == null) return 0;
      return (harga as num).toInt();
    } catch (e) {
      debugPrint('Gagal parsing harga: $harga, error: $e');
      return 0;
    }
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final name = item["nama_menu"];
      cartQuantities[name] = (cartQuantities[name] ?? 0) + 1;
    });

    _showAddToCartDialog(context, item);
  }

  void _showAddToCartDialog(BuildContext context, Map<String, dynamic> item) {
    int quantity = cartQuantities[item["nama_menu"]] ?? 1;
    int price = item["harga_menu"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartPage(
                  cartItems: cartQuantities,
                  menu_makanan: {},
                  menu_minuman: {},
                  menu_snack: {},
                  menu_paket: {
                    for (var item in menuItems)
                      item["nama_menu"]: _parseHarga(item["harga_menu"])
                  },
                ),
              ),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF078603),
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
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ),
                            Text(
                              item["nama_menu"],
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
              color: Color(0xFF078603),
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
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
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
                                        child: Image.network(
                                          item["foto_menu"] ?? '',
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Image.asset(
                                            'assets/no_image.png',
                                            width: 80,
                                            height: 80,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      ElevatedButton(
                                        onPressed: () => _addToCart(item),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            side: const BorderSide(
                                                color: Color(0xFF078603)),
                                          ),
                                        ),
                                        child: const Text(
                                          "Tambah",
                                          style: TextStyle(
                                              color: Color(0xFF078603)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item["nama_menu"],
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(item["deskripsi_menu"] ??
                                            "Tidak ada deskripsi"),
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
                                "Rp ${item["harga_menu"]}",
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
