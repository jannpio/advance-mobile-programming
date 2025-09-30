import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pioquinto_advmobprog/services/user_service.dart';
import 'package:pioquinto_advmobprog/widgets/custom_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  Future<Map<String, dynamic>> getUserData() async {
    return await _userService.getUserData();
  }

  void _openEditOptions(Map<String, dynamic> userData) {
    final loginType = userData['type'] ?? "unknown";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(16.sp),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const CustomText(
                text: "Update Username",
                color: Colors.black,
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditUsernameDialog(userData);
              },
            ),
            if (loginType == "firebase")
              ListTile(
                leading: const Icon(Icons.lock),
                title: const CustomText(
                  text: "Change Password",
                  color: Colors.black,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showChangePasswordDialog(userData['email']);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const CustomText(
                text: "Delete Account",
                color: Colors.black,
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteAccount(userData);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const CustomText(
                text: "Logout",
                color: Colors.black,
              ),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUsernameDialog(Map<String, dynamic> userData) {
    final TextEditingController controller =
        TextEditingController(text: userData['username'] ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const CustomText(
          text: "Update Username",
          fontSize: 16,
          color: Colors.black,
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new username"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const CustomText(
              text: "Cancel",
              color: Colors.black,
            ),
          ),
          TextButton(
            onPressed: () async {
              if (userData['type'] == "firebase") {
                await _userService.updateUsername(username: controller.text);
              } else {
                userData['username'] = controller.text;
                await _userService.updateUser(userData);
              }
              if (mounted) setState(() {});
              Navigator.pop(context);
            },
            child: const CustomText(
              text: "Save",
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(String email) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const CustomText(
          text: "Change Password",
          fontSize: 16,
          color: Colors.black,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Current Password"),
            ),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(hintText: "New Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const CustomText(
              text: "Cancel",
              color: Colors.black,
            ),
          ),
          TextButton(
            onPressed: () async {
              await _userService.resetPasswordFromCurrentPassword(
                email: email,
                currentPassword: currentPassController.text,
                newPassword: newPassController.text,
              );
              Navigator.pop(context);
            },
            child: const CustomText(
              text: "Update",
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(Map<String, dynamic> userData) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const CustomText(
          text: "Delete Account",
          fontSize: 16,
          color: Colors.black,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (userData['type'] == "firebase")
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration:
                    const InputDecoration(hintText: "Enter your password"),
              )
            else
              const CustomText(
                text:
                    "This will permanently delete your account from our database.",
                color: Colors.black,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const CustomText(
              text: "Cancel",
              color: Colors.black,
            ),
          ),
          TextButton(
            onPressed: () async {
              if (userData['type'] == "firebase") {
                await _userService.deleteAccount(
                  email: userData['email'],
                  password: passwordController.text,
                );
              } else {
                await _userService.deleteUser(userData['id'].toString());
              }
              if (mounted) {
                Navigator.pushReplacementNamed(context, "/login");
              }
            },
            child: const CustomText(
              text: "Delete",
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await _userService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: CustomText(
              text: "$label:",
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          Expanded(
            flex: 5,
            child: CustomText(
              text: value ?? "-",
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(Map<String, dynamic> userData) {
    final firstName = (userData['firstName'] ?? "").toString();
    final lastName = (userData['lastName'] ?? "").toString();

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return "${firstName[0].toUpperCase()}${lastName[0].toUpperCase()}";
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName[0].toUpperCase();
    } else if (userData['username']?.isNotEmpty == true) {
      return userData['username'][0].toUpperCase();
    } else if (userData['email']?.isNotEmpty == true) {
      return userData['email'][0].toUpperCase();
    }
    return "?";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: CustomText(
                text: "Error: ${snapshot.error}",
                color: Colors.black,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: CustomText(
                text: "No user data found",
                color: Colors.black,
              ),
            );
          }

          final userData = snapshot.data!;
          final loginType = userData['type'] ?? "unknown";
          final fullName =
              "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}"
                  .trim();

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.sp),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        _getInitials(userData),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: InkWell(
                        onTap: () => _openEditOptions(userData),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),

                // Full Name under avatar
                if (fullName.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: CustomText(
                      text: fullName,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                SizedBox(height: 20.h),

                // Display all user info
                _buildInfoRow("First Name", userData['firstName']),
                _buildInfoRow("Last Name", userData['lastName']),
                _buildInfoRow("Username", userData['username']),
                _buildInfoRow("Email", userData['email']),
                _buildInfoRow("Age", userData['age']?.toString()),
                _buildInfoRow("Gender", userData['gender']),
                _buildInfoRow("Contact Number", userData['contactNumber']),
                _buildInfoRow("Address", userData['address']),
                _buildInfoRow(
                  "Login Type",
                  "${loginType.toString()[0].toUpperCase()}${loginType.toString().substring(1)}",
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
