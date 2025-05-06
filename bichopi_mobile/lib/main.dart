import 'package:coba3/menu_paket.dart';
import 'package:coba3/reservasi.dart';
import 'package:coba3/profile.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'menu_makanan.dart' as makanan;
import 'menu_minuman.dart';
import 'menu_snack.dart' as snack;
import 'splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reedem.dart';
import 'cart_halaman.dart'; // Import halaman CartPage
import 'register.dart';
import 'login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nfafmiaxogrxxwjuyqfs.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5mYWZtaWF4b2dyeHh3anV5cWZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyNTIzMDcsImV4cCI6MjA1NTgyODMwN30.tsapVtnxkicRa-eTQLhKTBQtm7H9U1pfwBBdGdqryW0',
  );

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoginScreen(), // <-- ini ganti ke HomePage
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);
  int? _focusedIndex; // Menyimpan indeks item yang sedang ditekan
  final Map<String, int> _cart =
      {}; // Menyimpan item dalam keranjang (nama: jumlah)

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    HomePage(),
    ReservasiPage(selectedItem: {}),
    RewardPage(),
    ProfileScreen(),
  ];

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      _focusedIndex = index; // Set fokus saat item ditekan
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200), // Animasi lebih cepat
      curve: Curves.easeInOut,
    );
    // Reset fokus setelah animasi selesai (opsional)
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _focusedIndex = null;
      });
    });
  }

  void _onCartButtonTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          cartItems: _cart,
          menu_makanan: _getFoodMenuPrices(),
          menu_minuman: _getDrinkMenuPrices(),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> allMenus = [
    {"name": "Ricebowl", "price": 15000, "image": "assets/ricebowl.png"},
    {
      "name": "Mie Goreng Jawa",
      "price": 14000,
      "image": "assets/mie_goreng.png"
    },
    {"name": "Bakso Campur", "price": 13000, "image": "assets/bakso.png"},
    {
      "name": "Nasi Goreng Jawa",
      "price": 14000,
      "image": "assets/nasi_goreng.png"
    },
  ];
  List<Map<String, dynamic>> filteredMenus = [];

  @override
  void initState() {
    super.initState();
    filteredMenus = allMenus;
  }

  void _filterMenu(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredMenus = allMenus;
      } else {
        filteredMenus = allMenus
            .where((menu) =>
                menu["name"].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void navigateToMenuPage(String categoryName, BuildContext context) {
    if (categoryName == "Minuman") {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const DrinkMenuPage(
                  categoryName: '',
                )),
      );
    } else if (categoryName == "Snack") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => snack.SnackMenuPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                makanan.FoodMenuPage(categoryName: categoryName)),
      );
    }
  }

  void _addItemToCart(String itemName) {
    setState(() {
      _cart[itemName] = (_cart[itemName] ?? 0) + 1;
    });
    print("Keranjang: $_cart"); // Untuk debugging
  }

  Map<String, int> _getFoodMenuPrices() {
    Map<String, int> prices = {};
    // Anda perlu mengganti ini dengan data harga menu makanan Anda
    for (var menu in allMenus) {
      if (["Ricebowl", "Mie Goreng Jawa", "Bakso Campur", "Nasi Goreng Jawa"]
          .contains(menu["name"])) {
        prices[menu["name"]] = menu["price"] as int;
      }
    }
    return prices;
  }

  Map<String, int> _getDrinkMenuPrices() {
    Map<String, int> prices = {};
    // Anda perlu mengganti ini dengan data harga menu minuman Anda
    // Contoh: prices["Boba"] = 15000;
    return prices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: PageView(
        controller: _pageController,
        children: [
          HomeContent(addItemToCart: _addItemToCart), // Pass the callback
          _pages[1],
          _pages[2],
          _pages[3],
        ],
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _focusedIndex = null; // Reset fokus saat halaman berubah
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCartButtonTapped,
        backgroundColor: const Color(0xFF078603),
        elevation: 4,
        child: const Icon(Icons.shopping_cart, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0), // Kurangi padding vertikal
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(
                index: 0,
                icon: Icons.home,
                label: 'Home',
                onTap: _onBottomNavItemTapped,
                currentIndex: _currentIndex,
                isFocused: _focusedIndex == 0,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.chair_sharp,
                label: 'Reservasi',
                onTap: _onBottomNavItemTapped,
                currentIndex: _currentIndex,
                isFocused: _focusedIndex == 1,
              ),
              const SizedBox(width: 48.0), // Spasi untuk FAB
              _buildNavItem(
                index: 2,
                icon: Icons.redeem_rounded,
                label: 'Redeem',
                onTap: _onBottomNavItemTapped,
                currentIndex: _currentIndex,
                isFocused: _focusedIndex == 2,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.person_outline,
                label: 'Profil',
                onTap: _onBottomNavItemTapped,
                currentIndex: _currentIndex,
                isFocused: _focusedIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Function(int) onTap,
    required int currentIndex,
    bool isFocused = false,
  }) {
    const double iconSize =
        24.0; // Ukuran ikon yang lebih kecil untuk menghindari overflow
    const double textSize = 11.0; // Ukuran teks yang lebih kecil

    final bool isSelected = currentIndex == index;
    final Color color = isSelected ? const Color(0xFF078603) : Colors.grey;
    final double scale = isFocused ? 1.1 : 1.0; // Skala untuk efek "menonjol"

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150), // Durasi animasi
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: iconSize),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: textSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bagian HomeContent dan widget lainnya tetap sama seperti sebelumnya.
class HomeContent extends StatelessWidget {
  final Function(String) addItemToCart;

  @override
  HomeContent({required this.addItemToCart});
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          _buildSearchBar(),
          _buildCategoryList(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              "Paket",
              style: TextStyle(
                fontFamily: "Poppins-Light",
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          _buildCarousel(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              "Favorit",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(
              height: 8), // Mengurangi jarak antara "Favorit" dan menu
          _buildMenuList(addItemToCart: addItemToCart), // Pass the callback
        ],
      ),
    );
  }
}

Widget _buildCategoryList(BuildContext context) {
  final categories = [
    {"name": "Makanan", "icon": "assets/icon_miee.png"},
    {"name": "Minuman", "icon": "assets/icon_minuman1.png"},
    {"name": "Snack", "icon": "assets/icon_snack1.png"},
    {"name": "Paket", "icon": "assets/icon_paket1.png"},
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: categories.map((category) {
        return GestureDetector(
          onTap: () {
            if (category["name"] == "Makanan") {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        makanan.FoodMenuPage(categoryName: "Makanan")),
              );
            } else if (category["name"] == "Minuman") {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DrinkMenuPage(
                          categoryName: '',
                        )),
              );
            } else if (category["name"] == "Snack") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => snack.SnackMenuPage()),
              );
            } else if (category["name"] == "Paket") {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PaketMenuPage(
                          categoryName: '',
                        )), // Navigasi ke PaketMenuPage
              );
            }
          },
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF078603).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    category["icon"] as String,
                    width: 35,
                    height: 35,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category["name"] as String,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

Widget _buildTopBar() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF078603),
          Color(0xFF078603),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Halo, Carkecor 👋",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Mau makan apa hari ini?",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    // Tambahkan navigasi ke halaman notifikasi
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      "3",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                // Tambahkan aksi seperti membuka profil
              },
              child: AnimatedScale(
                scale: 1.1,
                duration: const Duration(milliseconds: 200),
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 22,
                  backgroundImage: NetworkImage(
                    "https://randomuser.me/api/portraits/men/1.jpg",
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildSearchBar() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: TextField(
      // Saat pengguna mengetik, filter menu
      decoration: InputDecoration(
        hintText: "Cari menu...",
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    ),
  );
}

Widget _buildCarousel() {
  final List<String> imageList = [
    "assets/paketramadhan.jpg",
    "assets/paketb.jpg",
    "assets/bicopi.jpg",
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: CarouselSlider(
      options: CarouselOptions(
        height: 180,
        autoPlay: true,
        enlargeCenterPage: true,
      ),
      items: imageList.map((image) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            image,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        );
      }).toList(),
    ),
  );
}

void _showItemDetails(BuildContext context, Map<String, String> item,
    Function(String itemName) addItemToCart) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Lebih melengkung
        ),
        backgroundColor: Colors.grey[50], // Latar belakang lebih lembut
        title: Text(
          item["name"]!,
          style: const TextStyle(
            fontWeight: FontWeight.w600, // Sedikit lebih tebal
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item["category"]!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item["description"]!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Rp ${item["price"]!}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    addItemToCart(item["name"]!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    elevation: 2, // Efek bayangan tipis
                  ),
                  child: const Text("Tambah"),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text("Batal"),
          ),
        ],
        actionsAlignment: MainAxisAlignment.end, // Tombol aksi di kanan
      );
    },
  );
}

Widget _buildMenuList({required Function(String p1) addItemToCart}) {
  final menuItems = [
    {
      "name": "Boba",
      "category": "Minuman",
      "description": "Minuman segar dan manis",
      "price": "15.000",
      "image": "assets/boba.png"
    },
    {
      "name": "Nasi Goreng Pedas",
      "category": "Makanan",
      "description": "Nasi goreng dengan cita rasa pedas",
      "price": "18.000",
      "image": "assets/ricebowl.png"
    },
    {
      "name": "Boba",
      "category": "Minuman",
      "description": "Minuman segar dan manis",
      "price": "15.000",
      "image": "assets/boba.png"
    },
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
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
                      child: Image.asset(
                        item["image"]!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: OutlinedButton(
                        onPressed: () {
                          _showItemDetails(context, item,
                              addItemToCart); // Sertakan addItemToCart
                        },
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
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["name"]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        item["category"]!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item["description"]!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "Rp ${item["price"]}",
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
