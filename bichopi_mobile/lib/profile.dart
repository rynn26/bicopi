import 'package:flutter/material.dart';
import 'edit_profile.dart'; // Import halaman edit profile

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Contoh data pengguna
  final String namaLengkap = "John Doe";
  final String username = "johndoe";
  final String email = "johndoe@example.com";
  final String noTelepon = "+6281234567890";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile Pengguna',
          style: TextStyle(color: Colors.white), // Warna title putih
        ),
        backgroundColor: Color(0xFF078603), // Hijau lebih elegan
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white), // Warna ikon kembali putih
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigasi ke halaman Edit Profile
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfilePage()),
                    );
                  },
                  icon: Icon(Icons.edit, color: Colors.white),
                  label: Text(
                    'Ubah Data Pribadi',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF078603), // Warna hijau elegan
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
