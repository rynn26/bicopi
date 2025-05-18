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
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
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
      if (referralCode.isNotEmpty) {
  try {
    final referralMatch = await Supabase.instance.client
        .from('affiliates')
        .select('id_user, referral_code')
        .ilike('referral_code', referralCode.trim())
        .maybeSingle();

    if (referralMatch != null && referralMatch['id_user'] != null) {
      idUserLevel = 4; // Affiliate
      userPoints = 0;
      referralBonus = 10;
      referralOwnerId = referralMatch['id_user'].toString().trim(); // aman
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
      const SnackBar(
          content: Text('Terjadi kesalahan saat memvalidasi kode referal.')),
    );
    return;
  }
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

      if (!hasReferral) {
      await Supabase.instance.client.from('members').insert({
      'id_user': user.id,
      'affiliate_id': null,
      'total_points': userPoints,
     'joined_at': DateTime.now().toIso8601String(),
     });
    }

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
          await Supabase.instance.client
              .from('affiliate_points_log')
              .insert({
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
            const SnackBar(
                content:
                    Text('Terjadi kesalahan saat memberikan bonus referal.')),
          );
        }
      }

      // 6. Successful registration
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pendaftaran berhasil! Silakan verifikasi email Anda.')),
      );

      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const login_page.LoginScreen()),
      );
    } on AuthException catch (error) {
      print('AuthException caught: ${error.message}'); // Debug log for auth error
      if (error.message.contains('user already registered') ||
          error.message.contains('email')) {
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
      backgroundColor: Colors.grey.shade100, // Latar belakang lembut
      body: SafeArea(
        child: SingleChildScrollView( // Membuat layar bisa di-scroll jika konten melebihi layar
          padding: const EdgeInsets.all(24.0), // Padding lebih besar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/bicopi_logo.png',
                  width: 100, // Ukuran logo sedikit lebih kecil
                  height: 100,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Buat Akun Baru',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF078603), // Warna primer yang lebih kuat
                ),
              ),
              const SizedBox(height: 24),
              _buildModernTextField(
                  controller: nameController, label: 'Nama Lengkap'),
              _buildModernTextField(
                  controller: phoneController, label: 'No Telepon', keyboardType: TextInputType.phone),
              _buildModernTextField(
                  controller: emailController, label: 'Email', keyboardType: TextInputType.emailAddress),
              _buildModernTextField(
                  controller: passwordController, label: 'Password', isPassword: true),
              _buildModernTextField(
                  controller: confirmPasswordController,
                  label: 'Konfirmasi Password',
                  isPassword: true),
              _buildModernTextField(
                  controller: referralCodeController, label: 'Kode Referal (Opsional)'),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor:Color(0xFF078603), // Warna tombol lebih menarik
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // BorderRadius lebih besar
                  ),
                  elevation: 3, // Tambahkan sedikit elevasi untuk kesan modern
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Daftar',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah punya akun?', style: TextStyle(fontSize: 16)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const login_page.LoginScreen()),
                      );
                    },
                    child: const Text('Login',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF078603))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType ?? TextInputType.text,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Color(0xFF078603), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}