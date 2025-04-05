import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(primary: Colors.green),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          prefixIconColor: Colors.green,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(seconds: 1),
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Hero(
          tag: "logo",
          child: Image.asset(
            'assets/tea.png',  // Pastikan path benar
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoggingIn = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoggingIn = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoggingIn = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Berhasil!')),
        );
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Logo
                                  Hero(
                    tag: "logo",
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'assets/tea.png',  // Pastikan path benar
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,  // Sesuaikan agar gambar proporsional
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                /// Welcome Text
                Text(
                  "Welcome Back!",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 10),
                Text(
                  "Login to continue",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 30),

                /// Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      /// Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Email tidak boleh kosong";
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return "Masukkan email yang valid";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      /// Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Password tidak boleh kosong";
                          if (value.length < 6) return "Password minimal 6 karakter";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      /// Login Button
                      ElevatedButton(
                        onPressed: _isLoggingIn ? null : _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isLoggingIn
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Login", style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                /// Forgot Password
                TextButton(
                  onPressed: () {},
                  child: const Text("Forgot Password?", style: TextStyle(color: Colors.green)),
                ),
                const SizedBox(height: 20),

                /// Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?", style: TextStyle(color: Colors.black)),
                    TextButton(
                      onPressed: () {},
                      child: const Text("Sign Up", style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
