import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pioquinto_advmobprog/services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();

  final _userService = UserService();
  bool _isLoading = false;

  String? _selectedGender;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleMongoRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await _userService.registerUser(
          _firstNameController.text.trim(),
          _lastNameController.text.trim(),
          int.tryParse(_ageController.text.trim()) ?? 0,
          _selectedGender ?? '',
          _contactNumberController.text.trim(),
          _emailController.text.trim(),
          _usernameController.text.trim(),
          _passwordController.text.trim(),
          _addressController.text.trim(),
        );

        await _userService.saveUserData(response);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MongoDB Register successful!')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MongoDB Register failed: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleFirebaseRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        final cred = await _userService.createAccountWithDetails(
          email: email,
          password: password,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          age: int.tryParse(_ageController.text.trim()) ?? 0,
          gender: _selectedGender ?? '',
          contactNumber: _contactNumberController.text.trim(),
          username: _usernameController.text.trim(),
          address: _addressController.text.trim(),
        );

        await _userService.saveUserData({
          "firstName": _firstNameController.text.trim(),
          "lastName": _lastNameController.text.trim(),
          "age": int.tryParse(_ageController.text.trim()) ?? 0,
          "gender": _selectedGender ?? '',
          "contactNumber": _contactNumberController.text.trim(),
          "email": email,
          "username": _usernameController.text.trim(),
          "address": _addressController.text.trim(),
          "uid": cred.user!.uid,
          "type": "firebase",
          "isActive": true,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase Register successful!')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase Register failed: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 1.2),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscureText = false, bool isNumber = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isNumber
          ? TextInputType.number
          : isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
      decoration: _inputDecoration(label, icon),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your $label';
        if (isEmail && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  SizedBox(height: 20.h),
                  const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // -------- First Name + Last Name --------
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_firstNameController, "First Name", Icons.person,),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildTextField(_lastNameController, "Last Name", Icons.person),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // -------- Age + Gender --------
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_ageController, "Age", Icons.cake, isNumber: true),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: _inputDecoration("Gender", Icons.wc),
                          items: ['Male', 'Female', 'Other']
                              .map((gender) => DropdownMenuItem(
                                    value: gender,
                                    child: Text(gender),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedGender = value),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Please select your gender' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(_contactNumberController, "Contact Number", Icons.phone,
                      isNumber: true),
                  const SizedBox(height: 16),
                  _buildTextField(_emailController, "Email", Icons.email, isEmail: true),
                  const SizedBox(height: 16),
                  _buildTextField(_usernameController, "Username", Icons.abc),
                  const SizedBox(height: 16),
                  _buildTextField(_passwordController, "Password", Icons.lock, obscureText: true),
                  const SizedBox(height: 16),
                  _buildTextField(_addressController, "Address", Icons.home),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleMongoRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        : const Text('Register with MongoDB',
                            style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleFirebaseRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.black)
                        : const Text('Register with Firebase',
                            style: TextStyle(color: Colors.black)),
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
