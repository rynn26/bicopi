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

  // Function to validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _signUp() async {
    // Validate email format
    final email = emailController.text.trim();
    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak valid!')),
      );
      return;
    }

    // Check if passwords match
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak sama!')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final password = passwordController.text;

    try {
      // 1. Try to register the user
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nama': nameController.text.trim(),
          'phone': phoneController.text.trim(),
        },
      );

      final user = response.user;
      if (user == null) throw Exception('Gagal mendaftar');

      final referralCode = referralCodeController.text.trim();
      int idUserLevel = 1; // Default Customer
      int userPoints = 100;
      int referralBonus = 0;
      String referralOwnerId = '';
      bool hasReferral = false;

      // 2. Validate referral code if present
      try {
        final referralMatch = await Supabase.instance.client
            .from('affiliates')
            .select('id')
            .eq('referral_code', referralCode)
            .maybeSingle();

        if (referralMatch != null) {
          idUserLevel = 4; // Affiliate
          userPoints = 0;
          referralBonus = 10;
          referralOwnerId = (referralMatch['id'] as String).trim();
          hasReferral = true;
          print('referralOwnerId setelah trim: $referralOwnerId');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kode referal tidak valid')),
          );
          return;
        }
      } catch (e) {
        print('Error saat memvalidasi kode referal: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan saat memvalidasi kode referal.')),
        );
        return;
      }

      // 3. Insert into 'users' table
      await Supabase.instance.client.from('users').insert({
        'id_user': user.id,
        'username': nameController.text.trim(),
        'email': email,
        'phone': phoneController.text.trim(),
        'id_user_level': idUserLevel,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 4. Insert user points log
      await Supabase.instance.client.from('member_points_log').insert({
        'member_id': user.id,
        'order_id': null,
        'points_earned': userPoints,
        'description': hasReferral
            ? 'Pendaftaran dengan referal'
            : 'Pendaftaran tanpa referal',
        'created_at': DateTime.now().toIso8601String(),
      });

      // 5. Insert affiliate points log (if referral exists)
      if (hasReferral && referralBonus > 0) {
        print('referralOwnerId sebelum insert affiliate_points_log: $referralOwnerId');
        try {
          await Supabase.instance.client.from('affiliate_points_log').insert({
            'affiliate_id': referralOwnerId,
            'member_id': user.id,
            'order_id': null,
            'points_earned': referralBonus,
            'description': 'Bonus referal dari ${nameController.text.trim()}',
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          print('Error saat insert ke affiliate_points_log: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terjadi kesalahan saat memberikan bonus referal.')),
          );
        }
      }

      // 6. Successful registration
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran berhasil! Silakan verifikasi email Anda.')),
      );

      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const login_page.LoginScreen()),
      );

    } on AuthException catch (error) {
      print('AuthException caught: ${error.message}'); // Debug log for auth error
      if (error.message.contains('user already registered') || error.message.contains('email')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email sudah digunakan.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auth error: ${error.message}')),
        );
      }
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