import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;

  const CartPage({super.key, required this.cart});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  void removeFromCart(int index) {
    setState(() {
      widget.cart.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Keranjang"),
      ),
      body: widget.cart.isEmpty
          ? const Center(
              child: Text("Keranjang kosong", style: TextStyle(fontSize: 18)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.cart.length,
              itemBuilder: (context, index) {
                final item = widget.cart[index];
                return Slidable(
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => removeFromCart(index),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Hapus',
                      ),
                    ],
                  ),
                  child: Card(
                    color: Colors.green.shade100,
                    child: ListTile(
                      leading: Image.asset(item['image'], width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(item['name']),
                      subtitle: Text("Rp ${item['price']}"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
