import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart' as login_page;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();

  bool isLoading = false;

 Future<void> _signUp() async {
  if (passwordController.text != confirmPasswordController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password tidak sama!')),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    final response = await Supabase.instance.client.auth.signUp(
      email: emailController.text.trim(),
      password: passwordController.text,
      data: {
        'nama': nameController.text.trim(),
        'phone': phoneController.text.trim(),
      },
    );

    final user = response.user;
    if (user == null) throw Exception('Gagal mendaftar');

    final referralCode = referralCodeController.text.trim();
    int idUserLevel = 1; // Default: customer

    // Cek validitas kode referal
    if (referralCode.isNotEmpty) {
      final referralMatch = await Supabase.instance.client
          .from('afiliasi')
          .select('id_afiliasi')
          .eq('kode_referal', referralCode)
          .maybeSingle();

      if (referralMatch != null) {
        idUserLevel = 4; // Level 4 = Member Afiliasi
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode referal tidak valid')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
    }

    // Simpan data user ke tabel users
    await Supabase.instance.client.from('users').insert({
      'id_user': user.id,
      'username': nameController.text.trim(),
      'email': emailController.text.trim(),
      'password': passwordController.text,
      'phone': phoneController.text.trim(),
      'id_user_level': idUserLevel,
      'created_at': DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pendaftaran berhasil! Silakan verifikasi email Anda sebelum login.')),
    );

    await Future.delayed(const Duration(seconds: 2));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const login_page.LoginScreen()));

  } on AuthException catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${error.message}')),
    );
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${error.toString()}')),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              const SizedBox(height: 30),
              Center(
                child: Image.asset(
                  'assets/bicopi_logo.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Daftar Akun',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTextField(controller: nameController, label: 'Nama Lengkap'),
              _buildTextField(controller: phoneController, label: 'No Telepon'),
              _buildTextField(controller: emailController, label: 'Email'),
              _buildTextField(controller: passwordController, label: 'Password', isPassword: true),
              _buildTextField(controller: confirmPasswordController, label: 'Konfirmasi Password', isPassword: true),
              _buildTextField(controller: referralCodeController, label: 'Kode Referal (Opsional)'),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF078603),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Daftar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const login_page.LoginScreen()),
                  );
                },
                child: const Text('Sudah punya akun? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: label.contains('Telepon') ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}