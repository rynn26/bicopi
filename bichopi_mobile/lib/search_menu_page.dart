import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_halaman.dart';

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
  Map<String, int> cartQuantities = {};
  String selectedCategory = 'Semua';
  String selectedSort = '';

  final List<String> categories = [
    'Semua',
    'Makanan',
    'Minuman',
    'Snack',
  ];

  final Map<String, int> categoryIds = {
    'Makanan': 2,
    'Minuman': 1,
    'Snack': 3,
  };

  @override
  void initState() {
    super.initState();
    fetchAllMenuItems();
  }

  Future<void> fetchAllMenuItems() async {
    try {
      final response = await supabase.from('menu').select(
          'nama_menu, foto_menu, deskripsi_menu, harga_menu, id_kategori_menu');

      final data = response.map<Map<String, dynamic>>((item) {
        return {
          "nama_menu": item["nama_menu"],
          "foto_menu": item["foto_menu"],
          "deskripsi_menu": item["deskripsi_menu"],
          "harga_menu": (item["harga_menu"] ?? 0).toInt(),
          "id_kategori_menu": item["id_kategori_menu"],
        };
      }).toList();

      setState(() {
        allMenuItems = data;
        applyFilters();
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    List<Map<String, dynamic>> items = List.from(allMenuItems);

    if (selectedCategory != 'Semua') {
      int? categoryId = categoryIds[selectedCategory];
      items = items
          .where((item) => item['id_kategori_menu'] == categoryId)
          .toList();
    }

    if (selectedSort == 'Termurah') {
      items.sort((a, b) => a['harga_menu'].compareTo(b['harga_menu']));
    } else if (selectedSort == 'Termahal') {
      items.sort((a, b) => b['harga_menu'].compareTo(a['harga_menu']));
    }

    setState(() => filteredMenuItems = items);
  }

  void addToCart(Map<String, dynamic> item) {
    setState(() {
      cartQuantities[item["nama_menu"]] =
          (cartQuantities[item["nama_menu"]] ?? 0) + 1;
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
              onChanged: (query) {
                allMenuItems = allMenuItems
                    .where((item) => item["nama_menu"]
                            .toString()
                            .toLowerCase()
                            .contains(query.toLowerCase()) ||
                        item["deskripsi_menu"]
                            .toString()
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                    .toList();
                applyFilters();
              },
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
         SizedBox(
  height: 50,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    itemCount: categories.length,
    separatorBuilder: (_, __) => const SizedBox(width: 8),
    itemBuilder: (context, index) {
      final category = categories[index];
      final isSelected = selectedCategory == category;

      return ChoiceChip(
        label: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFF078603),
        backgroundColor: Colors.grey[100],
        elevation: isSelected ? 3 : 0,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onSelected: (_) {
          setState(() {
            selectedCategory = category;
            applyFilters();
          });
        },
      );
    },
  ),
),

         Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        "Urutkan berdasarkan:",
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedSort.isEmpty ? null : selectedSort,
            hint: const Text("Pilih"),
            onChanged: (value) {
              setState(() {
                selectedSort = value ?? '';
                applyFilters();
              });
            },
            items: const [
              DropdownMenuItem(
                value: 'Termurah',
                child: Text("Termurah"),
              ),
              DropdownMenuItem(
                value: 'Termahal',
                child: Text("Termahal"),
              ),
            ],
          ),
        ),
      ),
    ],
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
                          subtitle: Text(item["deskripsi_menu"] ??
                              "Tidak ada deskripsi"),
                          trailing: Text(
                            "Rp ${item["harga_menu"]}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          onTap: () => addToCart(item),
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