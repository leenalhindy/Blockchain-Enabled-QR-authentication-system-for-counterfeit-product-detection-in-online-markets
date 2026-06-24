import 'package:flutter/material.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:my_app/screens/role/choose_role_screen.dart';
import 'package:my_app/screens/user/verify_product_screen.dart';
import 'package:my_app/screens/user/user_profile_screen.dart';
import 'package:my_app/screens/user/pending_sales_screen.dart'; // ✅ NEW

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final storage = const FlutterSecureStorage();

  String userName = "User";
  String userEmail = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // ======================================================
  // LOAD USER DATA
  // ======================================================
  Future<void> loadUserData() async {
    final firstName = await storage.read(key: "user_first");
    final fullName = await storage.read(key: "user_name");
    final email = await storage.read(key: "user_email");

    if (email != null) {
      userEmail = email;
    }

    if (firstName != null && firstName.isNotEmpty) {
      setState(() => userName = firstName);
    } else if (fullName != null && fullName.isNotEmpty) {
      setState(() => userName = fullName.split(' ')[0]);
    }
  }

  // ======================================================
  // LOGOUT
  // ======================================================
  Future<void> logoutUser() async {
    await storage.delete(key: "user_auth_token");
    await storage.delete(key: "user_first");
    await storage.delete(key: "user_name");
    await storage.delete(key: "user_email");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ChooseRoleScreen()),
      (route) => false,
    );
  }

  // ======================================================
  // NAVIGATION
  // ======================================================
  void navigateToVerify() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VerifyProductScreen()),
    );
  }

  void navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserProfileScreen()),
    );
  }

  void navigateToPendingSales() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PendingSalesScreen()),
    );
  }

  // ======================================================
  // DRAWER ITEM
  // ======================================================
  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.dark),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  // ======================================================
  // DRAWER
  // ======================================================
  Widget _buildDrawerContent() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.dark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.account_circle, color: Colors.white, size: 48),
                const SizedBox(height: 10),
                Text(
                  "Welcome, $userName",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          _drawerItem(
            Icons.qr_code_scanner,
            "Verify Product",
            navigateToVerify,
          ),
          _drawerItem(
            Icons.pending_actions,
            "Pending Sales Requests", // ✅ NEW
            navigateToPendingSales,
          ),
          _drawerItem(Icons.person_outline, "My Profile", navigateToProfile),

          const Divider(),
          _drawerItem(Icons.logout, "Logout", logoutUser),
        ],
      ),
    );
  }

  // ======================================================
  // UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "QR Authenticator",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.dark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawerContent(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.light, AppColors.light2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 100,
                  color: AppColors.deep,
                ),
                const SizedBox(height: 20),

                Text(
                  "Welcome, $userName!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  "Your authenticity journey starts here.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 40),

                _buildActionButton(
                  icon: Icons.qr_code_scanner,
                  label: "Verify Product",
                  onPressed: navigateToVerify,
                ),
                const SizedBox(height: 15),

                _buildActionButton(
                  icon: Icons.pending_actions,
                  label: "Pending Sales Requests", // ✅ NEW
                  onPressed: navigateToPendingSales,
                ),
                const SizedBox(height: 15),

                _buildActionButton(
                  icon: Icons.person_outline,
                  label: "My Profile",
                  onPressed: navigateToProfile,
                ),
                const SizedBox(height: 15),

                _buildActionButton(
                  icon: Icons.logout,
                  label: "Logout",
                  onPressed: logoutUser,
                  dark: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ======================================================
  // BUTTON
  // ======================================================
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool dark = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 20)),
        style: ElevatedButton.styleFrom(
          backgroundColor: dark
              ? const Color.fromARGB(255, 72, 2, 107)
              : AppColors.deep,
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
}
