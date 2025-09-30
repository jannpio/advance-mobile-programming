import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pioquinto_advmobprog/services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _userService = UserService();
  bool _isObscure = true;
  bool _isLoadingMongo = false;
  bool _isLoadingFirebase = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------- MongoDB Login ----------------
  Future<void> _handleMongoLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoadingMongo = true);
      try {
        final response = await _userService.loginUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        await _userService.saveUserData(response);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MongoDB Login successful!')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MongoDB Login failed: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isLoadingMongo = false);
      }
    }
  }

  // ---------------- Firebase Login ----------------
  Future<void> _handleFirebaseLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoadingFirebase = true);
      try {
        await _userService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase Login successful!')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase Login failed: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isLoadingFirebase = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/header.png',
                    width: 600.sp,
                    height: 100.sp,
                  ),
                  SizedBox(height: ScreenUtil().setHeight(20)),

                  const Text(
                    'Login',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // ---------------- Email ----------------
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ---------------- Password ----------------
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter your password'
                            : null,
                  ),
                  const SizedBox(height: 24),

                  // ---------------- Login with MongoDB ----------------
                  ElevatedButton(
                    onPressed: _isLoadingMongo ? null : _handleMongoLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoadingMongo
                        ? const CircularProgressIndicator(
                            color: Colors.amber, strokeWidth: 2)
                        : const Text(
                            'Login with MongoDB',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // ---------------- Login with Firebase ----------------
                  ElevatedButton(
                    onPressed: _isLoadingFirebase ? null : _handleFirebaseLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoadingFirebase
                        ? const CircularProgressIndicator(
                            color: Colors.blue, strokeWidth: 2)
                        : const Text(
                            'Login with Firebase',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // ---------------- Register Link ----------------
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text("Don't have an account? Register"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
