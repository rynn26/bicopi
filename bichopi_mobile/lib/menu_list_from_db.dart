import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_halaman.dart';

class MenuListFromDB extends StatefulWidget {
  final int categoryId;

  const MenuListFromDB({
    Key? key,
    required this.categoryId, required Function(String p1) addItemToCart,
  }) : super(key: key);

  @override
  State<MenuListFromDB> createState() => _MenuListFromDBState();
}

class _MenuListFromDBState extends State<MenuListFromDB> {
  final Map<String, int> cartQuantities = {};
  List<Map<String, dynamic>> menuItems = [];
  Map<String, int> menuMakanan = {};
  Map<String, int> menuMinuman = {};
  Map<String, int> menuSnack = {};
  Map<String, int> menuPaket = {};

  Future<List<Map<String, dynamic>>> fetchMenuData(int categoryId) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('menu')
        .select()
        .eq('id_kategori_menu', categoryId)
        .execute();

    if (response.error != null) {
      throw Exception('Failed to load data: ${response.error!.message}');
    }

    final data = List<Map<String, dynamic>>.from(response.data);
    menuItems = data;

    // Categorize menu items
    for (var item in data) {
      final String itemName = item['nama_menu'];
      final int price = int.tryParse(item['harga_menu'].toString()) ?? 0;
      final String category = item['kategori'] ?? '';

      if (category == 'makanan') {
        menuMakanan[itemName] = price;
      } else if (category == 'minuman') {
        menuMinuman[itemName] = price;
      } else if (category == 'snack') {
        menuSnack[itemName] = price;
      } else if (category == 'paket') {
        menuPaket[itemName] = price;
      }
    }

    return data;
  }

  void addItemToCart(BuildContext context, Map<String, dynamic> item) {
    final String itemName = item['nama_menu'];
    final int price = int.tryParse(item['harga_menu'].toString()) ?? 0;

    setState(() {
      cartQuantities[itemName] = (cartQuantities[itemName] ?? 0) + 1;
    });

    final int quantity = cartQuantities[itemName]!;

    // Show notification bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context); // Close the modal
            // Navigate to CartPage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartPage(
                  cartItems: cartQuantities,
                  menu_makanan: menuMakanan,
                  menu_minuman: menuMinuman,
                  menu_snack: menuSnack,
                  menu_paket: menuPaket,
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
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                            Text(
                              itemName,
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchMenuData(widget.categoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Menu tidak ditemukan.'));
        }

        final items = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final itemName = item['nama_menu'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: const Color.fromARGB(255, 255, 255, 255),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item['foto_menu'] ?? '',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 80),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 80,
                            child: OutlinedButton(
                              onPressed: () => addItemToCart(context, item),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                              ),
                              child: const Text(
                                "Tambah",
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              item['deskripsi_menu'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "Rp ${item['harga_menu']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

extension on PostgrestResponse {
  get error => null;
}