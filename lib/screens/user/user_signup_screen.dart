import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/screens/user/user_login_screen.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/widgets/app_header.dart'; // 💡 إضافة AppHeader

class UserSignUpScreen extends StatefulWidget {
  const UserSignUpScreen({super.key});

  @override
  State<UserSignUpScreen> createState() => _UserSignUpScreenState();
}

class _UserSignUpScreenState extends State<UserSignUpScreen> {
  final storage = const FlutterSecureStorage();

  final firstCtrl = TextEditingController();
  final lastCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController(); // 💡 جديد: متحكم رقم الهاتف
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  Future<void> registerUser() async {
    if (passCtrl.text.length < 8) {
      _showError("Password must be at least 8 characters.");
      return;
    }

    if (passCtrl.text != confirmCtrl.text) {
      _showError("Passwords do not match!");
      return;
    }

    // 💡 إضافة تحقق بسيط لرقم الهاتف (يمكن إضافة تحقق regex أكثر تعقيداً إذا لزم الأمر)
    if (phoneCtrl.text.trim().isEmpty) {
      _showError("Phone number is required.");
      return;
    }

    final name = "${firstCtrl.text.trim()} ${lastCtrl.text.trim()}";
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();
    final phoneNumber = phoneCtrl.text.trim(); // 💡 قراءة رقم الهاتف

    // —————— CALL API ——————
    // 💡 تم تعديل الدالة لتشمل رقم الهاتف
    final res = await ApiService.userSignup(name, email, password, phoneNumber);

    if (res["status"] == "success") {
      // 💡 تخزين رمز المصادقة (Token) فقط لضمان الأمان
      final token = res["auth_token"];

      if (token != null) {
        await storage.write(key: "user_auth_token", value: token);
      }
      await storage.write(key: "user_first", value: firstCtrl.text.trim());
      await storage.write(key: "user_last", value: lastCtrl.text.trim());
      await storage.write(
        key: "user_phone",
        value: phoneNumber,
      ); // 💡 حفظ رقم الهاتف

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Account created successfully!"),
          actions: [
            TextButton(
              child: const Text("Login"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserLoginScreen()),
                );
              },
            ),
          ],
        ),
      );
    } else {
      _showError(res["message"] ?? "Error occurred");
    }
  }

  // ========== ERROR DIALOG ==========
  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 تحديد إذا كانت الشاشة صغيرة أم لا
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;

    // تحديد البادينغ بناءً على حجم الشاشة
    final paddingH = isSmallScreen ? 25.0 : 40.0;
    final paddingV = isSmallScreen ? 30.0 : 40.0;

    return Scaffold(
      body: Row(
        children: [
          // LEFT PANEL (Desktop Only)
          if (!isSmallScreen)
            Expanded(
              flex: 1,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/admin_bg.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Welcome to\nQR Authenticator",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          // RIGHT PANEL (Form)
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: paddingH,
                    vertical: paddingV,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 💡 إضافة الهيدر للشاشات الصغيرة
                      if (isSmallScreen) const AppHeader(),

                      isSmallScreen
                          ? const SizedBox(height: 30)
                          : const SizedBox(height: 50),

                      const Text(
                        "Create User Account",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 30),

                      _input("First Name", firstCtrl),
                      const SizedBox(height: 15),
                      _input("Last Name", lastCtrl),
                      const SizedBox(height: 15),
                      _input("Email", emailCtrl),
                      const SizedBox(height: 15),

                      // 💡 NEW: حقل رقم الهاتف
                      _input(
                        "Phone Number",
                        phoneCtrl,
                        keyboard: TextInputType.phone,
                      ),
                      const SizedBox(height: 15),

                      _input("Password (min 8)", passCtrl, obscure: true),
                      const SizedBox(height: 15),
                      _input("Confirm Password", confirmCtrl, obscure: true),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dark,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Register",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UserLoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: AppColors.dark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // 💡 إضافة مسافة سفلية عند الشاشات الصغيرة
                      if (isSmallScreen) const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💡 تحديث الدالة المساعدة لتقبل نوع لوحة المفاتيح
  Widget _input(
    String label,
    TextEditingController c, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard, // 💡 تحديد نوع لوحة المفاتيح
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
