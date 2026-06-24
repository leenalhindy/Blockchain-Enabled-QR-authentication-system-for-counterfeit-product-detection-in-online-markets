import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/screens/role/choose_role_screen.dart';
import 'package:my_app/screens/user/change_password_screen.dart'; // 💡 استيراد الشاشة الفعلية
import 'package:my_app/screens/user/edit_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final storage = const FlutterSecureStorage();
  String firstName = "N/A";
  String lastName = "";
  String email = "N/A";
  bool loading = true;
  String phoneNumber = "N/A";

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // ------------------------- DATA LOADING -------------------------

  Future<void> _loadProfileData() async {
    final storedEmail = await storage.read(key: "user_email");
    final storedFirstName = await storage.read(key: "user_first");
    final storedLastName = await storage.read(key: "user_last");
    final storedPhone = await storage.read(key: "user_phone");

    setState(() {
      email = storedEmail ?? "Email Not Found";
      firstName = storedFirstName ?? "User";
      lastName = storedLastName ?? "";
      loading = false;
      phoneNumber = storedPhone ?? "N/A";
    });
  }

  // ------------------------- NAVIGATION / ACTIONS -------------------------

  void navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
  }

  // 💡 جديد: دالة للانتقال إلى شاشة تعديل الملف الشخصي
  void navigateToEditProfile() async {
    final bool? profileUpdated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );

    // إذا تم تحديث الملف الشخصي، أعد تحميل البيانات
    if (profileUpdated == true) {
      _loadProfileData();
    }
  }

  Future<void> handleLogout() async {
    await storage.delete(key: "user_auth_token");
    await storage.delete(key: "user_first");
    await storage.delete(key: "user_last");
    await storage.delete(key: "user_email");
    await storage.delete(key: "user_phone");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ChooseRoleScreen()),
      (route) => false,
    );
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

  // ------------------------- BUILD METHOD -------------------------

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 600 ? 500.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.dark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Container(
            width: contentWidth,
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. أيقونة المستخدم الرئيسية
                      const Icon(
                        Icons.account_circle,
                        size: 120,
                        color: AppColors.dark,
                      ),
                      const SizedBox(height: 30),

                      // 2. عرض الاسم الأول
                      _buildInfoRow("First Name:", firstName),
                      const SizedBox(height: 15),

                      // 3. عرض الاسم الأخير
                      _buildInfoRow("Last Name:", lastName),
                      const SizedBox(height: 15),

                      // 4. عرض البريد الإلكتروني
                      _buildInfoRow("Email:", email),
                      const SizedBox(height: 15),
                      // 💡 جديد: عرض رقم الهاتف
                      _buildInfoRow("Phone:", phoneNumber),

                      const SizedBox(height: 50),
                      _buildSettingsButton(
                        icon: Icons.edit,
                        label: "Edit Profile",
                        onPressed: navigateToEditProfile,
                        color: AppColors.deep,
                      ),
                      const SizedBox(height: 20),
                      // 5. زر تغيير كلمة المرور الرئيسي
                      _buildSettingsButton(
                        icon: Icons.lock,
                        label: "Change Password",
                        onPressed: navigateToChangePassword,
                        color: AppColors.deep,
                      ),

                      const SizedBox(height: 20),

                      // زر تسجيل الخروج (كإجراء ثانوي)
                      _buildSettingsButton(
                        icon: Icons.logout,
                        label: "Logout",
                        onPressed: handleLogout,
                        color: Colors.red[600]!,
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // 💡 ويدجت مُساعد لزر الإعدادات
  Widget _buildSettingsButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: 280,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
      ),
    );
  }

  // 💡 ويدجت مُساعد لإنشاء صف عرض المعلومات
  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, color: Colors.black87),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
