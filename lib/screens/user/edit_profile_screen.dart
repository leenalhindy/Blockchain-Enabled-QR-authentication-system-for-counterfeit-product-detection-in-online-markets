// lib/screens/user/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final storage = const FlutterSecureStorage();
  final firstCtrl = TextEditingController();
  final lastCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfileData();
  }

  @override
  void dispose() {
    firstCtrl.dispose();
    lastCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  // دالة لجلب البيانات الحالية من التخزين وعرضها في حقول الإدخال
  Future<void> _loadCurrentProfileData() async {
    final storedFirstName = await storage.read(key: "user_first");
    final storedLastName = await storage.read(key: "user_last");
    final storedEmail = await storage.read(key: "user_email");
    final storedPhone = await storage.read(key: "user_phone");

    setState(() {
      firstCtrl.text = storedFirstName ?? "";
      lastCtrl.text = storedLastName ?? "";
      emailCtrl.text = storedEmail ?? "";
      phoneCtrl.text = storedPhone ?? "";
    });
  }

  // دالة لمعالجة حفظ التعديلات
  Future<void> _handleSaveProfile() async {
    final newFirstName = firstCtrl.text.trim();
    final newLastName = lastCtrl.text.trim();
    final newEmail = emailCtrl.text.trim();
    final newPhoneNumber = phoneCtrl.text.trim();

    // التحقق الأساسي من الحقول
    if (newFirstName.isEmpty ||
        newLastName.isEmpty ||
        newEmail.isEmpty ||
        newPhoneNumber.isEmpty) {
      _showSnackbar("All fields are required.", Colors.orange);
      return;
    }
    if (!newEmail.contains('@')) {
      _showSnackbar("Please enter a valid email address.", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    // استدعاء API لتحديث الملف الشخصي
    final result = await ApiService.updateUserProfile(
      email: newEmail, // البريد الإلكتروني يستخدم كمعرف للتحديث في الـ backend
      firstName: newFirstName,
      lastName: newLastName,
      phoneNumber: newPhoneNumber,
    );

    setState(() => _isLoading = false);

    if (result["status"] == "success") {
      // تحديث البيانات في التخزين المحلي بعد الحفظ الناجح
      await storage.write(key: "user_first", value: newFirstName);
      await storage.write(key: "user_last", value: newLastName);
      await storage.write(key: "user_email", value: newEmail);
      await storage.write(key: "user_phone", value: newPhoneNumber);

      _showSnackbar(
        result["message"] ?? "Profile updated successfully!",
        Colors.green,
      );
      Navigator.pop(
        context,
        true,
      ); // إرجاع 'true' للإشارة إلى أن البيانات تم تحديثها
    } else {
      _showSnackbar(
        result["message"] ?? "Failed to update profile.",
        Colors.red,
      );
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final formWidth = screenWidth > 600 ? 500.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.dark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Container(
            width: formWidth,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.light2,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Update Your Information",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                const Divider(height: 30),

                _input("First Name", firstCtrl),
                const SizedBox(height: 15),
                _input("Last Name", lastCtrl),
                const SizedBox(height: 15),
                _input(
                  "Email",
                  emailCtrl,
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                _input(
                  "Phone Number",
                  phoneCtrl,
                  keyboard: TextInputType.phone,
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSaveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          "Save Changes",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController c, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
