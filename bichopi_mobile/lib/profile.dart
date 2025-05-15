import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'ubah_password.dart';
import 'main.dart'; // HomePage

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfilePage createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('profil')
            .select()
            .eq('id_user', user.id)
            .single();

        setState(() {
          _nameController.text = response['nama'] ?? '';
          _emailController.text = response['email'] ?? '';
          _phoneController.text = response['phone']?.toString() ?? '';
          _imageUrl = response['image_url'];
          _isLoading = false;
        });
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _imageFile = file;
      });
      await _uploadImageToSupabase(file);
    }
  }

  Future<void> _uploadImageToSupabase(File file) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final fileExt = p.extension(file.path);

    final filePath = 'profile_pictures/${user.id}$fileExt';

    try {
      final fileBytes = await file.readAsBytes(); // convert to Uint8List

      await Supabase.instance.client.storage
          .from('profileimages')
          .uploadBinary(filePath, fileBytes,
              fileOptions: const FileOptions(upsert: true));

      final imageUrl = Supabase.instance.client.storage
          .from('profileimages')
          .getPublicUrl(filePath);

      // Simpan URL ke database
      await Supabase.instance.client
          .from('profil')
          .update({'image_url': imageUrl})
          .eq('id_user', user.id);

      setState(() {
        _imageUrl = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto profil berhasil diperbarui")),
      );
    } catch (e) {
      print("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal upload gambar: $e")),
      );
    }
  }

  Future<void> _updateUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('profil').update({
          'nama': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
        }).eq('id_user', user.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data berhasil diperbarui")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal update data: $e")),
        );
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16, // Ukuran teks diperkecil
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
        ),
      ),
    );
  }

  Widget _buildRoundedTextField(
      String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14), // Ukuran teks input diperkecil
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF2E7D32), fontSize: 14), // Ukuran teks label diperkecil
          prefixIcon: Icon(icon, color: Color(0xFF2E7D32), size: 20), // Ukuran ikon diperkecil
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Padding diperkecil
        ),
      ),
    );
  }

  Widget _buildClickableRoundedBox(
      String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            const BoxShadow(
              color: Colors.black12, blurRadius: 3, offset: Offset(1, 1)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2E7D32), size: 20), // Ukuran ikon diperkecil
                const SizedBox(width: 10),
                Text(text, style: const TextStyle(fontSize: 14)), // Ukuran teks diperkecil
              ],
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: Color(0xFF2E7D32)), // Ukuran ikon diperkecil
          ],
        ),
      ),
    );
  }

  Widget _buildIconButtonWithText(IconData icon, VoidCallback onPressed, String text, {Color? backgroundColor, Color? iconColor, TextStyle? textStyle}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40, // Ukuran tombol ikon diperkecil
          height: 40, // Ukuran tombol ikon diperkecil
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? Colors.green,
              foregroundColor: iconColor ?? Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Sudut lebih kecil
              ),
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 40),
            ),
            child: Icon(icon, size: 20), // Ukuran ikon diperkecil
          ),
        ),
        const SizedBox(height: 3), // Jarak diperkecil
        Text(
          text,
          style: textStyle ?? const TextStyle(fontSize: 10, color: Colors.grey), // Ukuran teks diperkecil
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Warna latar belakang AppBar sebelumnya
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF078603), // Warna AppBar sebelumnya
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  left: 25,
                  top: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomePage()),
                      );
                    },
                  ),
                ),
                const Center(
                  child: Text(
                    "Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0), // Padding keseluruhan diperkecil
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50, // Ukuran avatar diperkecil
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_imageUrl != null
                                  ? NetworkImage(_imageUrl!)
                                  : const AssetImage(
                                          "assets/foto_profile.png")
                                      as ImageProvider),
                          backgroundColor: Colors.grey[300],
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(15), // Sudut lebih kecil
                            child: Container(
                              padding: const EdgeInsets.all(6.0), // Padding diperkecil
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white, width: 1), // Border lebih tipis
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 16, color: Colors.white), // Ukuran ikon diperkecil
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15), // Jarak diperkecil
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _nameController.text,
                          style: const TextStyle(
                            fontSize: 18, // Ukuran teks nama diperkecil
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 3), // Jarak diperkecil
                        Text(
                          _emailController.text,
                          style: const TextStyle(fontSize: 12, color: Colors.grey), // Ukuran teks email diperkecil
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20), // Jarak diperkecil
                  Container(
                    padding: const EdgeInsets.all(12.0), // Padding diperkecil
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12), // Sudut lebih kecil
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Informasi Akun"),
                        _buildRoundedTextField(
                            "Nama Lengkap", _nameController, Icons.person_outline),
                        _buildRoundedTextField(
                            "Email", _emailController, Icons.email_outlined),
                        _buildRoundedTextField(
                            "No. Telepon", _phoneController, Icons.phone_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15), // Jarak diperkecil
                  Container(
                    padding: const EdgeInsets.all(12.0), // Padding diperkecil
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12), // Sudut lebih kecil
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Pengaturan Keamanan"),
                        _buildClickableRoundedBox(
                            "Ubah Password", Icons.lock_outline, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const UbahPasswordScreen()),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20), // Jarak diperkecil
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIconButtonWithText(
                        Icons.save_alt,
                        _updateUserData,
                        "Simpan",
                        backgroundColor: Colors.green,
                        textStyle: const TextStyle(fontSize: 10), // Ukuran teks tombol diperkecil
                      ),
                      _buildIconButtonWithText(
                        Icons.logout,
                        _logout,
                        "Logout",
                        backgroundColor: Colors.redAccent,
                        textStyle: const TextStyle(fontSize: 10), // Ukuran teks tombol diperkecil
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}