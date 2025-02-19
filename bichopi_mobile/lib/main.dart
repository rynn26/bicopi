import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'menu_makanan.dart'; // Pastikan halaman menu_page.dart sudah ada

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
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void navigateToMenuPage(String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodMenuPage(categoryName: categoryName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            _buildSearchBar(),
            _buildCategoryList(),
            _buildCarousel(),
            _buildMenuList(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Keranjang",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFFB2FF59)],
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
      "assets/ricebowl.png",
      "assets/ricebowl.png",
      "assets/ricebowl.png",
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

  Widget _buildCategoryList() {
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
          return _CategoryItem(
            categoryName: category["name"] as String,
            icon: category["icon"] as IconData,
            onTap: () {
              // Navigasi ke halaman menu dengan kategori yang dipilih
              navigateToMenuPage(category["name"] as String);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuList() {
    final menuItems = [
      {
        "name": "Nasi Goreng Pedas",
        "price": "18.000",
        "image": "assets/ricebowl.png"
      },
      {
        "name": "2 Rice Bowl",
        "price": "20.000",
        "image": "assets/ricebowl.png"
      },
      {"name": "Nasi", "price": "18.000", "image": "assets/ricebowl.png"},
      {
        "name": "Coffe Latte",
        "price": "15.000",
        "image": "assets/ricebowl.png"
      },
      {
        "name": "Chocolate Coffe",
        "price": "16.000",
        "image": "assets/ricebowl.png"
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 7),
            child: Text(
              "Rekomendasi Menu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      item["image"]!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    item["name"]!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Rp ${item["price"]}"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String categoryName;
  final IconData icon;
  final VoidCallback onTap;  // Tambahkan callback onTap

  const _CategoryItem({
    required this.categoryName,
    required this.icon,
    required this.onTap,  // Tambahkan parameter onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,  // Jalankan onTap saat item diketuk
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[200],
            child: Icon(icon, size: 30, color: Colors.green),
            ),
          const SizedBox(height: 4),
          Text(
            categoryName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}