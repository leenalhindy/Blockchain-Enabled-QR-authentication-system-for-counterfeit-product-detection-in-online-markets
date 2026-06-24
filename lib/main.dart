import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 💡 الاستيراد المفقود الذي قد يكون سبب المشكلة
import 'package:my_app/screens/welcome/welcome_screen.dart';
import 'package:my_app/services/init_admin.dart';
import 'package:my_app/screens/admin/admin_dashboard.dart';
import 'package:my_app/screens/user/user_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdminInit.setupAdmin();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 💡 دالة لتحديد الشاشة الأولية
  Future<Widget> _getInitialScreen() async {
    const storage = FlutterSecureStorage();
    final userToken = await storage.read(key: "user_auth_token");
    final adminToken = await storage.read(key: "admin_auth_token");

    // نتحقق من وجود الرمز وصلاحيته (نعتبره صالحًا إذا وُجد)
    if (adminToken != null && adminToken.isNotEmpty) {
      return const AdminDashboardScreen();
    } else if (userToken != null && userToken.isNotEmpty) {
      return const UserHomeScreen();
    } else {
      return const WelcomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "QR Authenticator",
      // 💡 استخدام FutureBuilder لانتظار نتيجة فحص الرموز
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // 💡 FIX: نضمن إرجاع قيمة Widget غير فارغة (non-null) في حال فشل الـ Future
            return snapshot.data ?? const WelcomeScreen();
          }

          // أثناء التحميل/الفحص، اعرض شاشة تحميل بسيطة بمركز الشاشة
          return const Scaffold(
            backgroundColor: Color(0xFFF7F5FF), // استخدام لون خلفية التطبيق
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6E57A5), // استخدام لون داكن من AppColors
              ),
            ),
          );
        },
      ),
    );
  }
}
