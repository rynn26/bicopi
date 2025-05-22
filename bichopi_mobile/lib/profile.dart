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
          _emailController.text = user.email ?? ''; // Use Supabase user email as primary
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

      // Save URL to database
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
            'id_user': user.id, // Ensure id_user is provided for upsert
            'nama': _nameController.text,
            'email': _emailController.text, // Update email in profile table too
            'phone': _phoneController.text.isEmpty ? null : _phoneController.text, // Handle empty phone number
          },
          onConflict: 'id_user', // Specify conflict key for upsert
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
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800], // Darker grey for section titles
        ),
      ),
    );
  }

  Widget _buildRoundedTextField(
      String label, TextEditingController controller, IconData icon, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 16, color: Colors.black87), // Slightly larger input text
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF1E88E5), size: 24), // Primary green for icons
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15), // More rounded corners
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0), // Lighter border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2.0), // Primary green on focus
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 18), // Slightly larger padding
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
        padding: const EdgeInsets.all(18), // Slightly larger padding
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15), // Consistent rounding
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1), // Softer shadow
              blurRadius: 8,
              offset: const Offset(0, 3), // Subtle elevation
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1E88E5), size: 24), // Primary green for icons
                const SizedBox(width: 15),
                Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)), // Larger text
              ],
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey), // Grey arrow for subtlety
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String text, VoidCallback onPressed, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color, // Use provided color
            foregroundColor: Colors.white,
            elevation: 4, // Slightly more elevation
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15), // Consistent rounding
            ),
            padding: const EdgeInsets.symmetric(vertical: 14), // Larger padding for better touch target
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), // Larger and slightly bolder text
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5), // Primary blue AppBar
        elevation: 0, // No shadow under app bar
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25), // Rounded bottom corners for AppBar
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0), // Increased overall padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60, // Slightly larger avatar
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_imageUrl != null
                                      ? NetworkImage(_imageUrl!)
                                      : const AssetImage(
                                          "assets/foto_profile.png")
                                          as ImageProvider),
                          backgroundColor: Colors.grey[200],
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            borderRadius: BorderRadius.circular(20), // Larger for better touch
                            child: Container(
                              padding: const EdgeInsets.all(8.0), // Larger padding
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50), // Secondary green for camera button
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white, width: 2), // Thicker white border
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 20, color: Colors.white), // Larger icon
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _nameController.text.isNotEmpty ? _nameController.text : "Your Name",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900], // Darker text for name
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _emailController.text.isNotEmpty ? _emailController.text : "youremail@example.com",
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]), // Subtler grey for email
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16.0), // Larger padding for section
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15), // Consistent rounding
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
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
                            "Email", _emailController, Icons.email_outlined, readOnly: true), // Email should generally be read-only
                        _buildRoundedTextField(
                            "Phone Number", _phoneController, Icons.phone_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
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
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(Icons.save, "Save Changes", _updateUserData, const Color(0xFF1E88E5)), // Primary blue for save
                      _buildActionButton(Icons.logout, "Logout", _logout, Colors.redAccent), // Red for logout
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}