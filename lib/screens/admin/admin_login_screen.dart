import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/screens/admin/admin_dashboard.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/widgets/app_header.dart';
import 'package:my_app/services/api_service.dart'; // 💡 استيراد ApiService

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final storage = const FlutterSecureStorage();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  // 💡 متغير لإظهار مؤشر التحميل
  bool _isLoading = false;

  // ---------------- LOGIN FUNCTION ----------------
  Future<void> loginAdmin() async {
    final inputEmail = emailCtrl.text.trim();
    final inputPass = passCtrl.text.trim();

    if (inputEmail.isEmpty || inputPass.isEmpty) {
      _showError("Please enter both email and password.");
      return;
    }

    setState(() => _isLoading = true); // بدء التحميل

    // 1. الاتصال بالـ API لتسجيل الدخول
    final res = await ApiService.adminLogin(inputEmail, inputPass);

    setState(() => _isLoading = false); // إنهاء التحميل

    if (res["status"] == "success") {
      final token = res["admin_auth_token"];

      if (token != null) {
        // 2. تخزين رمز المصادقة الفعلي (Admin Token)
        await storage.write(key: "admin_auth_token", value: token);
      }
      // 💡 NEW: حفظ الإيميل كمرجع (Admin Email)
      await storage.write(key: "admin_email", value: inputEmail);

      // الانتقال إلى لوحة التحكم
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        (route) => false,
      );
    } else {
      // عرض رسالة الخطأ الواردة من الـ API
      _showError(res["message"] ?? "Incorrect admin email or password.");
    }
  }

  // 💡 دالة مُساعدة موحدة لعرض رسائل الخطأ
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login Failed"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // 💡 تحديد إذا كانت الشاشة صغيرة أم لا
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;

    // تحديد البادينغ بناءً على حجم الشاشة
    final paddingH = isSmallScreen ? 25.0 : 40.0;
    final paddingV = isSmallScreen ? 30.0 : 50.0;

    return Scaffold(
      // 💡 استخدام Row فقط للشاشات الكبيرة، وإلا يتم عرض المحتوى مباشرة في body
      body: Row(
        children: [
          // --------------- Left Image Panel (Desktop Only) ---------------
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
                child: Center(
                  child: Text(
                    "Welcome Back, Admin!",
                    textAlign: TextAlign.center, // لضمان التوسيط
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ),
              ),
            ),

          // ---------------- Right Login Form ----------------
          Expanded(
            // 💡 زيادة Flex في الشاشات الصغيرة لتشغل 100% من العرض المتاح (على افتراض أن Left Panel غير موجود)
            flex: 1,
            child: SingleChildScrollView(
              // 💡 لضمان عدم حدوث تجاوز في حالة لوحة المفاتيح
              child: ConstrainedBox(
                // 💡 لضمان أن Column يشغل ارتفاع الشاشة على الأقل في حالة الشاشات الكبيرة
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: paddingH,
                    vertical: paddingV,
                  ),
                  child: Column(
                    mainAxisAlignment: isSmallScreen
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // إظهار الهيدر فقط على الشاشات الصغيرة/عند عدم وجود الصورة
                      if (isSmallScreen) const AppHeader(),

                      isSmallScreen
                          ? const SizedBox(height: 30)
                          : const SizedBox(height: 50),

                      const Text(
                        "Admin Login",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        "Enter your admin credentials below.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),

                      const SizedBox(height: 40),

                      // ---------------- Email ----------------
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          filled: true,
                          fillColor: AppColors.light,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ---------------- Password ----------------
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          filled: true,
                          fillColor: AppColors.light,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // ---------------- Login Button ----------------
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : loginAdmin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dark,
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
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
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
}
