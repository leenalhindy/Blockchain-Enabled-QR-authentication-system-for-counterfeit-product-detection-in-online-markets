// lib/screens/user/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final storage = const FlutterSecureStorage();
  String email = "N/A";
  bool isSaving = false; // 💡 حالة التحميل

  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  @override
  void dispose() {
    oldPassCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserEmail() async {
    final storedEmail = await storage.read(key: "user_email");
    setState(() {
      email = storedEmail ?? "Email Not Found";
    });
  }

  Future<void> handleChangePassword() async {
    if (email == "N/A" || email == "Email Not Found") {
      _showSnackbar(
        "Cannot change password: User email is unknown.",
        Colors.red,
      );
      return;
    }

    final oldPass = oldPassCtrl.text.trim();
    final newPass = newPassCtrl.text.trim();
    final confirmPass = confirmPassCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showSnackbar("Please enter all password fields.", Colors.orange);
      return;
    }

    if (newPass != confirmPass) {
      _showSnackbar(
        "New password and confirmation do not match.",
        Colors.orange,
      );
      return;
    }

    if (newPass.length < 8) {
      _showSnackbar(
        "New password must be at least 8 characters.",
        Colors.orange,
      );
      return;
    }

    setState(() => isSaving = true); // 🔑 بدء التحميل

    final result = await ApiService.changePassword(email, oldPass, newPass);

    setState(() => isSaving = false); // 🔑 إنهاء التحميل

    if (result["status"] == "success") {
      _showSnackbar(
        result["message"] ?? "Password changed successfully!",
        Colors.green,
      );
      oldPassCtrl.clear();
      newPassCtrl.clear();
      confirmPassCtrl.clear();
      // إغلاق الشاشة والعودة بعد التحديث الناجح
      Navigator.pop(context);
    } else {
      _showSnackbar(
        result["message"] ?? "Failed to change password.",
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
          "Change Password",
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
                  "Update Your Password",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                const Divider(height: 30),

                _input("Old Password", oldPassCtrl, _obscureOld, (value) {
                  setState(() {
                    _obscureOld = value;
                  });
                }),
                const SizedBox(height: 15),

                _input(
                  "New Password (min 8 characters)",
                  newPassCtrl,
                  _obscureNew,
                  (value) {
                    setState(() {
                      _obscureNew = value;
                    });
                  },
                ),
                const SizedBox(height: 15),

                _input(
                  "Confirm New Password",
                  confirmPassCtrl,
                  _obscureConfirm,
                  (value) {
                    setState(() {
                      _obscureConfirm = value;
                    });
                  },
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : handleChangePassword, // 🔑 تعطيل الزر عند التحميل
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child:
                      isSaving // 🔑 عرض المؤشر عند التحميل
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
                          "Update Password",
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

  // 💡 ويدجت مُساعد لحقل الإدخال (مع زر إظهار/إخفاء النص)
  Widget _input(
    String label,
    TextEditingController c,
    bool obscure,
    ValueChanged<bool> onToggle,
  ) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: AppColors.dark,
          ),
          onPressed: () => onToggle(!obscure),
        ),
      ),
    );
  }
}
