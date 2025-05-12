import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UbahPasswordScreen extends StatefulWidget {
  const UbahPasswordScreen({super.key});

  @override
  _UbahPasswordScreenState createState() => _UbahPasswordScreenState();
}

class _UbahPasswordScreenState extends State<UbahPasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  double _passwordStrengthValue = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.transparent;

  final supabase = Supabase.instance.client;

  void _checkPasswordStrength(String password) {
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) strength += 0.25;

    setState(() {
      _passwordStrengthValue = strength;
      if (strength <= 0.25) {
        _passwordStrengthText = 'Lemah';
        _passwordStrengthColor = Colors.red;
      } else if (strength <= 0.5) {
        _passwordStrengthText = 'Sedang';
        _passwordStrengthColor = Colors.orange;
      } else if (strength <= 0.75) {
        _passwordStrengthText = 'Baik';
        _passwordStrengthColor = Colors.yellow[700]!;
      } else {
        _passwordStrengthText = 'Kuat';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  Future<void> _ubahPassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      _showMessage("Konfirmasi password tidak cocok.");
      return;
    }

    if (_passwordStrengthValue < 0.75) {
      _showMessage("Password belum cukup kuat. Gunakan kombinasi huruf besar, angka, dan simbol.");
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showMessage("Pengguna tidak ditemukan.");
        return;
      }

      final response = await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        _showMessage("Gagal mengubah password.");
        return;
      }

      await supabase
          .from('users')
          .update({'password': newPassword})
          .eq('id_user', user.id);

      _showMessage("Password berhasil diubah.");
    } catch (e) {
      _showMessage("Gagal mengubah password: $e");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ubah Password"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPasswordField(
              "Password saat ini",
              _currentPasswordController,
              _obscureCurrentPassword,
              () {
                setState(() {
                  _obscureCurrentPassword = !_obscureCurrentPassword;
                });
              },
            ),
            const SizedBox(height: 10),
            _buildPasswordField(
              "Password baru",
              _newPasswordController,
              _obscureNewPassword,
              () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
              onChanged: _checkPasswordStrength,
            ),
            if (_passwordStrengthText.isNotEmpty) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _passwordStrengthValue,
                backgroundColor: Colors.grey[300],
                color: _passwordStrengthColor,
                minHeight: 8,
              ),
              const SizedBox(height: 4),
              Text(
                'Kekuatan: $_passwordStrengthText',
                style: TextStyle(
                  color: _passwordStrengthColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 10),
            _buildPasswordField(
              "Konfirmasi Password baru",
              _confirmPasswordController,
              _obscureConfirmPassword,
              () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _ubahPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Simpan Perubahan",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Batalkan",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscureText,
    VoidCallback toggleVisibility, {
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}