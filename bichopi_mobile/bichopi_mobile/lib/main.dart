import 'package:coba3/reservasi.dart';
import 'package:coba3/profile.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'menu_makanan.dart' as makanan;
import 'menu_minuman.dart';
import 'menu_snack.dart' as snack;
import 'reedem.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(),
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    HomeContent(),
    CartPage(selectedItem: {},),
    ProfilePage(),
     RedeemPage(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
    filteredMenus = allMenus; // Set awal ke semua menu
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
        MaterialPageRoute(builder: (context) => const DrinkMenuPage()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: PageView(
        controller: _pageController,
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.chair), label: 'reservasi'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person), label: 'Profile'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.redeem_rounded), label: 'Reedem'),
              ],
              currentIndex: _currentIndex,
              selectedItemColor: Color(0xFF078603),
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: false,
              backgroundColor: Colors.white,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          _buildSearchBar(),
          _buildCategoryList(context),
          _buildCarousel(),
          _buildMenuList(),
        ],
      ),
    );
  }
}

Widget _buildCategoryList(BuildContext context) {
  final categories = [
    {"name": "Makanan", "icon": Icons.fastfood},
    {"name": "Minuman", "icon": Icons.local_cafe},
    {"name": "Snack", "icon": Icons.lunch_dining},
    {"name": "Lainnya", "icon": Icons.more_horiz},
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
                MaterialPageRoute(builder: (context) => const DrinkMenuPage()),
              );
            } else if (category["name"] == "Snack") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => snack.SnackMenuPage()),
              );
            }
          },
          child: Column(
            children: [
              CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  child: Icon(category["icon"] as IconData,
                      size: 30, color: Color(0xFF078603))),
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

Widget _buildMenuList() {
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
          color: const Color.fromARGB(
              255, 255, 255, 255), // Warna latar belakang lembut
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
                      width: 80, // Sesuaikan lebar tombol dengan gambar
                      child: OutlinedButton(
                        onPressed: () {},
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
