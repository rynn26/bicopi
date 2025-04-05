import 'package:flutter/material.dart';
import 'input_reservasi.dart'; // Import halaman formulir reservasi
import 'bukti_reservasi.dart';

void main() {
  runApp(const CartPage());
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ReservationScreen(),
    );
  }
}

class ReservationScreen extends StatelessWidget {
  const ReservationScreen({super.key});

  final List<Map<String, String>> categories = const [
    {
      'name': 'Kursi Deretan Depan',
      'capacity': 'Kapasitas 20 Orang',
      'image': 'assets/reservasi1.png',
    },
    {
      'name': 'VIP Plate',
      'capacity': 'Kapasitas 10 Orang',
      'image': 'assets/reservasi2.png',
    },
    {
      'name': 'Kursi Biasa',
      'capacity': 'Kapasitas 50 Orang',
      'image': 'assets/reservasi3.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFF078603),
        elevation: 0,
       
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              
              'Daftar Kategori Tempat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
           SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Navigasi ke halaman formulir reservasi
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ReservationFormScreen(
                              category: categories[index],
                            ),
                      ),
                    );
                  },
                  child: _buildCategoryCard(categories[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF078603),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Reservasi Tempat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Bichopi, Indonesia',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, String> category) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    elevation: 5, // Elevasi lebih tinggi agar efek shadow lebih jelas
    shadowColor: Colors.grey.withOpacity(0.5),
    margin: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            // Gambar dengan border radius
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Image.asset(
                category['image']!,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            // Overlay Gradient untuk membuat tampilan lebih elegan
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            // Label kategori di pojok atas kiri
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Featured",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category['name']!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category['capacity']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Ikon kecil untuk menunjukkan interaktivitas
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


}
