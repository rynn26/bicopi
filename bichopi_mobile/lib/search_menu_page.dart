import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_halaman.dart';
import 'chatbot_rekomendasi.dart'; // Import halaman chatbot

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cari Menu App',
      theme: ThemeData(
        primarySwatch: Colors.green, // Tema utama hijau
        hintColor: Colors.grey[600],
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.black87),
          titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            textStyle: const TextStyle(fontSize: 16.0),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          titleTextStyle: TextStyle(fontWeight: FontWeight.w500),
          subtitleTextStyle: TextStyle(color: Colors.black54),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.grey[400]!),
          ),
          backgroundColor: Colors.grey[200],
          selectedColor: Colors.green[200],
          labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          brightness: Brightness.light,
        ),
      ),
      home: const SearchMenuPage(),
    );
  }
}

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
  String searchQuery = ''; // untuk pencarian

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
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load menu items")),
      );
    }
  }

  Future<void> _updateCartInDatabase(String itemName, int quantity, int price) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now().toIso8601String();

    if (quantity > 0) {
      await supabase.from('keranjang').upsert({
        'user_id': user.id,
        'item_name': itemName,
        'quantity': quantity,
        'price': price,
        'created_at': now,
        'updated_at': now,
      }, onConflict: 'user_id,item_name');
    } else {
      await supabase
          .from('keranjang')
          .delete()
          .eq('user_id', user.id)
          .eq('item_name', itemName);
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

    if (searchQuery.isNotEmpty) {
      items = items.where((item) =>
          item["nama_menu"]
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          item["deskripsi_menu"]
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase())).toList();
    }

    if (selectedSort == 'Termurah') {
      items.sort((a, b) => a['harga_menu'].compareTo(b['harga_menu']));
    } else if (selectedSort == 'Termahal') {
      items.sort((a, b) => b['harga_menu'].compareTo(a['harga_menu']));
    }

    setState(() => filteredMenuItems = items);
  }

  void addToCart(Map<String, dynamic> item) {
    final String itemName = item["nama_menu"];
    final int price = item["harga_menu"];

    setState(() {
      cartQuantities[itemName] = (cartQuantities[itemName] ?? 0) + 1;
    });

    _updateCartInDatabase(itemName, cartQuantities[itemName]!, price);
    _showAddToCartDialog(context, item);
  }

  void _showAddToCartDialog(BuildContext context, Map<String, dynamic> item) {
    int quantity = cartQuantities[item["nama_menu"]] ?? 1;
    int price = item["harga_menu"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                              "Jumlah: $quantity",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                            Text(
                              item["nama_menu"],
                              style: const TextStyle(
                                fontSize: 16,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
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
                  child: const Text("Lihat Keranjang"),
                ),
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
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (query) {
                      setState(() {
                        searchQuery = query;
                        applyFilters();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Cari menu...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                SizedBox(
                  width: 48.0,
                  height: 48.0,
                  child: FloatingActionButton(
                    heroTag: "cartButton",
                    backgroundColor: Theme.of(context).primaryColor,
                    onPressed: () {
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
                    child: const Icon(Icons.shopping_cart, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;

                    return ChoiceChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Theme.of(context).primaryColor,
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Urutkan:",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final item = filteredMenuItems[index];
                          return Card(
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  item["foto_menu"] ?? '',
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset('assets/no_image.png',
                                          width: 70, height: 70),
                                ),
                              ),
                              title: Text(
                                item["nama_menu"] ?? "-",
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(item["deskripsi_menu"] ?? "Tidak ada deskripsi"),
                              trailing: Text(
                                "Rp ${item["harga_menu"]}",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                              ),
                              onTap: () => addToCart(item),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          // Tombol Chatbot Mengambang
          Positioned(bottom: 16.0,
            right: 16.0,
            child: SizedBox(
              width: 60.0,
              height: 60.0,
              child: FloatingActionButton(
                heroTag: "chatbotButton",
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChatbotRekomendasi()),
                  );
                },
                child: Container(
                  width: 60.0,
                  height: 60.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    gradient: LinearGradient(
                      colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColorDark ?? Theme.of(context).primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 30.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}