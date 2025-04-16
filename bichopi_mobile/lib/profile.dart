import 'package:flutter/material.dart';
import 'ubah_password.dart'; // Pastikan file ini ada

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfilePage createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfileScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: "John Doe");
  final TextEditingController _emailController =
      TextEditingController(text: "JohnDoe@gmail.com");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF078603),
        automaticallyImplyLeading: false, // Menghilangkan tombol back
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage("assets/foto_profile.png"),
              ),
            ),
            const SizedBox(height: 10),

            // Nama & Email
            Center(
              child: Column(
                children: [
                  Text(
                    _nameController.text,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _emailController.text,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Informasi Akun
            _buildSectionTitle("Informasi Akun"),
            _buildEditableTextField("Nama Lengkap", _nameController),
            _buildEditableTextField("Email", _emailController),

            const SizedBox(height: 20),

            // Pengaturan keamanan
            _buildSectionTitle("Pengaturan Keamanan"),
            _buildClickableBox("Ubah Password", Icons.lock, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UbahPasswordScreen()),
              );
            }),

            const SizedBox(height: 30),

            // Tombol Logout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Logout",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF078603),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk Judul Section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Widget untuk Input yang Bisa Diedit
  Widget _buildEditableTextField(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // Widget untuk Kotak Klik "Ubah Password"
  Widget _buildClickableBox(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.black54),
                const SizedBox(width: 10),
                Text(text, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}