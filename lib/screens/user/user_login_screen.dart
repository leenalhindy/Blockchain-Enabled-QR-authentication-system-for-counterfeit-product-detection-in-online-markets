import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/screens/user/user_home_screen.dart';
import 'package:my_app/screens/user/user_signup_screen.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/widgets/app_header.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final storage = const FlutterSecureStorage();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  // ---------------------- LOGIN FUNCTION ----------------------
  Future<void> loginUser() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter both email and password.");
      return;
    }

    // 🔵 CALL LOGIN API
    final res = await ApiService.userLogin(email, password);

    // إذا فشل الدخول → أظهر الخطأ
    if (res["status"] != "success") {
      _showError(res["message"] ?? "Incorrect email or password.");
      return;
    }

    // -------------------- SUCCESSFUL LOGIN --------------------
    final token = res["auth_token"];
    final user = res["user"];

    if (token != null) {
      await storage.write(key: "user_auth_token", value: token);
    }

    // 🔥 Save user information properly
    if (user != null) {
      final fullName = user["name"] ?? "";
      final email = user["email"] ?? "";
      final phone = user["phone_number"] ?? "";

      // فصل الاسم الأول والأخير
      final parts = fullName.split(" ");
      final firstName = parts.isNotEmpty ? parts.first : "";
      final lastName = parts.length > 1 ? parts.sublist(1).join(" ") : "";

      // 🟢 Save into secure storage
      await storage.write(key: "user_name", value: fullName);
      await storage.write(key: "user_first", value: firstName);
      await storage.write(key: "user_last", value: lastName);
      await storage.write(key: "user_email", value: email);
      await storage.write(key: "user_phone", value: phone);
    }

    // GO TO USER HOME
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const UserHomeScreen()),
    );
  }

  // ---------------------- ERROR POPUP ----------------------
  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login Failed"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // --------------------------- UI ---------------------------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;

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
                      if (isSmallScreen) const AppHeader(),

                      isSmallScreen
                          ? const SizedBox(height: 30)
                          : const SizedBox(height: 50),

                      const Center(
                        child: Text(
                          "User Login",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // EMAIL FIELD
                      TextField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                          labelText: "Email",
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // PASSWORD FIELD
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dark,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 40,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // SIGNUP LINK
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserSignUpScreen(),
                            ),
                          );
                        },
                        child: const Center(
                          child: Text(
                            "Don't have an account? Sign Up",
                            style: TextStyle(
                              color: AppColors.dark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

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
}

// ================= SIGN CHALLENGE =================
