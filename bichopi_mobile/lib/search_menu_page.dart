import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_halaman.dart'; // Pastikan Anda sudah membuat halaman keranjang

class SearchMenuPage extends StatefulWidget {
  const SearchMenuPage({super.key});

  @override
  State<SearchMenuPage> createState() => _SearchMenuPageState();
}

class _SearchMenuPageState extends State<SearchMenuPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> allMenuItems = [];
  List<Map<String, dynamic>> filteredMenuItems = [];
  bool isLoading = true;
  Map<String, int> cartQuantities = {}; // Menyimpan jumlah item dalam keranjang

  @override
  void initState() {
    super.initState();
    fetchAllMenuItems();
  }

  // Fetch menu items from Supabase
  Future<void> fetchAllMenuItems() async {
    try {
      final response = await supabase.from('menu').select(
          'nama_menu, foto_menu, deskripsi_menu, harga_menu, id_kategori_menu');

      final data = response.map<Map<String, dynamic>>((item) {
        return {
          "nama_menu": item["nama_menu"],
          "foto_menu": item["foto_menu"],
          "deskripsi_menu": item["deskripsi_menu"],
          "harga_menu": (item["harga_menu"] != null)
              ? (item["harga_menu"] is double)
                  ? item["harga_menu"]
                      .toInt() // If the price is a double, convert it to int
                  : item["harga_menu"] is int
                      ? item["harga_menu"]
                      : 0 // If the price is neither int nor double, default to 0
              : 0, // If no price is available, default to 0
          "id_kategori_menu": item["id_kategori_menu"],
        };
      }).toList();

      setState(() {
        allMenuItems = data;
        filteredMenuItems = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  // Filter menu items based on search query
  void filterMenu(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMenuItems = allMenuItems;
      } else {
        filteredMenuItems = allMenuItems.where((item) {
          final name = item["nama_menu"].toString().toLowerCase();
          final desc = item["deskripsi_menu"]?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              desc.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // Add item to cart
  void addToCart(Map<String, dynamic> item) {
    setState(() {
      cartQuantities[item["nama_menu"]] =
          (cartQuantities[item["nama_menu"]] ?? 0) + 1;
    });
    _showAddToCartDialog(context, item);
  }

  // Show dialog when item is added to cart
  void _showAddToCartDialog(BuildContext context, Map<String, dynamic> item) {
    int quantity = cartQuantities[item["nama_menu"]] ?? 1;
    int price = item["harga_menu"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  menu_makanan: {},
                  menu_minuman: {
                    for (var item in filteredMenuItems)
                      item["nama_menu"]: item["harga_menu"]
                  },
                  menu_snack: {},
                  menu_paket: {},
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
      appBar: AppBar(
        title: const Text("Cari Menu"),
        backgroundColor: const Color(0xFF078603),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: filterMenu,
              decoration: InputDecoration(
                hintText: "Cari menu apa saja...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredMenuItems.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final item = filteredMenuItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item["foto_menu"] ?? '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset('assets/no_image.png',
                                      width: 60, height: 60),
                            ),
                          ),
                          title: Text(item["nama_menu"] ?? "-"),
                          subtitle: Text(
                              item["deskripsi_menu"] ?? "Tidak ada deskripsi"),
                          trailing: Text(
                            "Rp ${item["harga_menu"]}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () =>
                              addToCart(item), // Add to cart when tapped
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
