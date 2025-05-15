import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_halaman.dart';

class MenuListFromDB extends StatefulWidget {
  const MenuListFromDB({Key? key, required Function(String p1) addItemToCart, required int categoryId}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    fetchMenuData(); // Panggil data saat inisialisasi
    _loadCartFromDatabase(); // Sinkronisasi keranjang dengan tampilan awal
  }

  Future<void> fetchMenuData() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('menu')
        .select()
        .eq('id_kategori_menu', 5) // Ambil data hanya dari kategori ID 5
        .execute();

    if (response.error != null) {
      throw Exception('Failed to load data: ${response.error!.message}');
    }

    final data = List<Map<String, dynamic>>.from(response.data);
    setState(() {
      menuItems = data;

      // Kategorisasi menu
      for (var item in data) {
        final String itemName = item['nama_menu'];
        final int price = _parsePrice(item['harga_menu']);
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
    });
  }

  int _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll('.', '').replaceAll(',', '');
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  Future<void> _loadCartFromDatabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('keranjang')
        .select('item_name, quantity')
        .eq('user_id', user.id)
        .execute();

    if (response.error == null) {
      final data = List<Map<String, dynamic>>.from(response.data);
      setState(() {
        for (var item in data) {
          cartQuantities[item['item_name']] = item['quantity'] as int;
        }
      });
    }
  }

  Future<void> _updateCartInDatabase(String itemName, int quantity, int price) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now().toIso8601String();

    if (quantity > 0) {
      await Supabase.instance.client.from('keranjang').upsert({
        'user_id': user.id,
        'item_name': itemName,
        'quantity': quantity,
        'price': price,
        'created_at': now,
        'updated_at': now,
      }, onConflict: 'user_id,item_name');
    } else {
      await Supabase.instance.client
          .from('keranjang')
          .delete()
          .eq('user_id', user.id)
          .eq('item_name', itemName);
    }
  }

  void _increaseQuantity(String itemName, int price) {
    setState(() {
      cartQuantities[itemName] = (cartQuantities[itemName] ?? 0) + 1;
    });
    _updateCartInDatabase(itemName, cartQuantities[itemName]!, price);
  }

  void _decreaseQuantity(String itemName, int price) {
    if (cartQuantities[itemName] == null || cartQuantities[itemName]! <= 0) return;

    setState(() {
      cartQuantities[itemName] = cartQuantities[itemName]! - 1;
    });

    if (cartQuantities[itemName]! > 0) {
      _updateCartInDatabase(itemName, cartQuantities[itemName]!, price);
    } else {
      cartQuantities.remove(itemName);
      _updateCartInDatabase(itemName, 0, price);
    }
  }

  void _showAddToCartDialog(BuildContext context, Map<String, dynamic> item) {
    final String itemName = item['nama_menu'];
    final int price = _parsePrice(item['harga_menu']);
    final int quantity = cartQuantities[itemName] ?? 0;

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
                  menu_makanan: menuMakanan,
                  menu_minuman: menuMinuman,
                  menu_snack: menuSnack,
                  menu_paket: menuPaket,
                ),
              ),
            ).then((_) {
              _loadCartFromDatabase(); // Reload cart data
            });
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
                              quantity > 0 ? "Jumlah Pesanan: $quantity" : "0 Pesanan",
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
    return menuItems.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final itemName = item['nama_menu'];
                final harga = _parsePrice(item['harga_menu']);
                final quantity = cartQuantities[itemName] ?? 0;

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
                                onPressed: () => _showAddToCartDialog(context, item),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                ),
                                child: const Text(
                                  "Tambah",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => _decreaseQuantity(itemName, harga),
                                ),
                                Text('$quantity'),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                  onPressed: () => _increaseQuantity(itemName, harga),
                                ),
                              ],
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
                          "Rp $harga",
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
  }
}

extension on PostgrestResponse {
  get error => null;
}
