import 'package:flutter/material.dart';
import 'cart_page.dart';

class FoodMenuPage extends StatefulWidget {
  final String categoryName;
  
  const FoodMenuPage({super.key, required this.categoryName});

  @override
  State<FoodMenuPage> createState() => _FoodMenuPageState();
}

class _FoodMenuPageState extends State<FoodMenuPage> {
  List<Map<String, dynamic>> menuItems = [
    {
      "name": "Ricebowl",
      "price": 15000,
      "image": "assets/ricebowl.png",
      "description": "Ricebowl dengan ayam crispy dan saus spesial.",
    },
  ];

  List<Map<String, dynamic>> cart = [];

  void addToCart(Map<String, dynamic> item) {
    setState(() {
      cart.add(item);
    });
  }

  int getTotalPrice() {
  return cart.fold(0, (sum, item) => sum + (item['price'] as int));
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.categoryName, style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bichopi, Indonesia", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Icon(Icons.star, color: Colors.white, size: 16),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Tambahkan Menu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(item['image'], width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Rp ${item['price']}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['description']),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => addToCart(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("+", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                );
              },
            ),
          ),
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.green,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white),
                  Text("${cart.length} Pesanan", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("Rp ${getTotalPrice()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}