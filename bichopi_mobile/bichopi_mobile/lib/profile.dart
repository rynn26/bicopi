import 'package:flutter/material.dart';
import 'edit_profile.dart'; // Import halaman edit profile

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Contoh data pengguna
  final String namaLengkap = "Muzaka Najih";
  final String username = "muzaka86_";
  final String email = "muzaka@example.com";
  final String noTelepon = "+6281234567890";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70), // Samakan tinggi dengan contoh
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25), // Radius membulat untuk estetika
            bottomRight: Radius.circular(25),
          ),
          child: AppBar(
            title: Text(
              'Profile Pengguna',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color(0xFF078603), // Warna hijau elegan
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white), // Warna ikon kembali putih
            elevation: 0, // Hilangkan shadow agar lebih smooth
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  child: Icon(Icons.person, size: 70, color: Colors.white),
                ),
              ),
              SizedBox(height: 30),
              _buildProfileField("Nama Lengkap", namaLengkap),
              _buildProfileField("Username", username),
              _buildProfileField("Email", email),
              _buildProfileField("No Telepon", noTelepon),
              SizedBox(height: 20),
              
              // Ubah data pribadi sebagai teks dengan ikon
              GestureDetector(
                onTap: () {
                  // Navigasi ke halaman Edit Profile
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfilePage()),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.article, size: 22, color: Colors.black), // Ikon di sebelah kiri
                    SizedBox(width: 8), // Spasi antara ikon dan teks
                    Text(
                      'Ubah data pribadi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 5),
          TextField(
            controller: TextEditingController(text: value),
            readOnly: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }
}
