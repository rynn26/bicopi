import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'login.dart';
import 'ubah_password.dart';
import 'main.dart'; // Assuming HomePage is in main.dart

// Define a refined green color palette as top-level constants
const Color _primaryGreen = Color(0xFF4CAF50); // A balanced, medium green
const Color _darkGreen = Color(0xFF2E7D32); // Deeper green for accents
const Color _lightGreen = Color(0xFFE8F5E9); // Very light green for backgrounds
const Color _accentGreen = Color(0xFF81C784); // Slightly brighter accent for highlights
const Color _greyText = Color(0xFF616161); // Darker grey for main text
const Color _lightGrey = Color(0xFFBDBDBD); // Lighter grey for hints/dividers

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
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
          _emailController.text = user.email ?? '';
          _phoneController.text = response['phone']?.toString() ?? '';
          _imageUrl = response['image_url'];
          _isLoading = false;
        });
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load user data: $e")),
          );
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
      }
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
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to upload image.")),
        );
      }
      return;
    }

    final fileExt = p.extension(file.path);
    final filePath = 'profile_pictures/${user.id}$fileExt';

    try {
      final fileBytes = await file.readAsBytes();

      await Supabase.instance.client.storage
          .from('profileimages')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = Supabase.instance.client.storage
          .from('profileimages')
          .getPublicUrl(filePath);

      await Supabase.instance.client
          .from('profil')
          .update({'image_url': imageUrl}).eq('id_user', user.id);

      setState(() {
        _imageUrl = imageUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated successfully!")),
        );
      }
    } catch (e) {
      print("Upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload image: $e")),
        );
      }
    }
  }

  Future<void> _updateUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('profil').upsert(
          {
            'id_user': user.id,
            'nama': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
          },
          onConflict: 'id_user',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile data updated successfully!")),
          );
        }
      } catch (e) {
        print("Update data error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update profile data: $e")),
          );
        }
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
      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 8.0),
      child: Text(
        title,

        style: GoogleFonts.poppins( // Applied Poppins
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _darkGreen,

        ),
      ),
    );
  }

  Widget _buildRoundedTextField(
      String label, TextEditingController controller, IconData icon, {bool readOnly = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,

        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 14, color: _greyText), // Applied Poppins
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: _lightGrey, fontSize: 12), // Applied Poppins
          prefixIcon: Icon(icon, color: _primaryGreen, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 12),

          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildClickableRoundedBox(
      String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(

        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),

            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [

                Icon(icon, color: _darkGreen, size: 20),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: GoogleFonts.poppins(fontSize: 14, color: _greyText, fontWeight: FontWeight.w500), // Applied Poppins
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios,
                size: 12, color: _lightGrey),

          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String text, VoidCallback onPressed, Color color) {
    return Expanded(
      child: Padding(

        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),

              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600), // Applied Poppins
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: _lightGreen,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        elevation: 0,
        title: Text( // Changed to Text() as GoogleFonts.poppins() is not const

          "Profile",
          style: GoogleFonts.poppins( // Applied Poppins to AppBar title
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(

            bottom: Radius.circular(20),

          ),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: _isLoading

          ? const Center(child: CircularProgressIndicator(color: _primaryGreen, strokeWidth: 2.5))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(

                          radius: 45,
                          backgroundColor: _accentGreen.withOpacity(0.3),

                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_imageUrl != null
                                      ? NetworkImage(_imageUrl!)
                                      : const AssetImage(
                                          "assets/foto_profile.png") as ImageProvider),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,

                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: const EdgeInsets.all(6.0),
                              decoration: BoxDecoration(
                                color: _accentGreen,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _accentGreen.withOpacity(0.25),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 16, color: Colors.white),

                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _nameController.text.isNotEmpty ? _nameController.text : "Your Name",
                          style: GoogleFonts.poppins( // Applied Poppins
                            fontSize: 18,
                            fontWeight: FontWeight.bold,

                            color: const Color(0xFF078603), // Darker green for name

                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _emailController.text.isNotEmpty ? _emailController.text : "youremail@example.com",

                          style: GoogleFonts.poppins(fontSize: 12, color: _greyText), // Applied Poppins

                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(

                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Account Information"),
                        _buildRoundedTextField(
                            "Full Name", _nameController, Icons.person_outline),
                        _buildRoundedTextField(
                            "Email", _emailController, Icons.email_outlined, readOnly: true),
                        _buildRoundedTextField(
                            "Phone Number", _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Security Settings"),
                        _buildClickableRoundedBox(
                            "Change Password", Icons.lock_outline, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const UbahPasswordScreen()),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [

                      _buildActionButton(Icons.save, "Save Changes", _updateUserData, _primaryGreen),

                      _buildActionButton(Icons.logout, "Logout", _logout, Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}