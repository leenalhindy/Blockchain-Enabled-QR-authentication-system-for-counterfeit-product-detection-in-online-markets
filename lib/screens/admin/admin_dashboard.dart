import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/screens/admin/generate_qr_screen.dart';
import 'package:my_app/screens/admin/qr_gallery_screen.dart';
import 'package:my_app/screens/role/choose_role_screen.dart';
import 'package:my_app/services/api_service.dart';

// =========================================================
// شاشة لوحة التحكم الرئيسية (AdminDashboardScreen)
// =========================================================

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final storage = const FlutterSecureStorage();

  int products = 0;
  int fake = 0;
  int admins = 1;
  int logsCount = 0; // Total Scans
  int usersCount = 0;

  List<dynamic> logsList = [];

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    // 💡 NEW: Fetch all data from the new consolidated API endpoint
    final dashboardResult = await ApiService.fetchDashboardStats();

    if (dashboardResult["status"] == "success") {
      final stats = dashboardResult["stats"] as Map<String, dynamic>;
      final activity = dashboardResult["recent_activity"] as List<dynamic>;

      // 💡 UPDATE: Use data from the API result
      setState(() {
        products = stats["total_products"] ?? 0;
        fake = stats["fake_detections"] ?? 0;
        admins = stats["total_admins"] ?? 1;
        usersCount = stats["total_users"] ?? 0;
        logsCount = stats["total_scans"] ?? 0; // Used for Total Scans card
        logsList = activity; // Detailed activity logs
      });
    } else {
      // Fallback or error handling
      print(
        "Failed to load dashboard data from API: ${dashboardResult["message"]}",
      );
      // إذا فشل الـ API، سنبقي على القيم الافتراضية
    }
  }

  // ---------- LOGOUT ----------
  Future<void> logoutAdmin() async {
    await storage.delete(key: "is_logged_in");
    await storage.delete(key: "admin_auth_token");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ChooseRoleScreen()),
      (route) => false,
    );
  }

  String timeAgo(String timeString) {
    DateTime t = DateTime.parse(timeString);
    Duration diff = DateTime.now().difference(t);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hour ago";
    return "Yesterday";
  }

  // 💡 Drawer content - تم إضافة خيار User List
  Widget _buildDrawerContent() {
    return Container(
      color: AppColors.dark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.dark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "QR System",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Admin Panel",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          _drawerItem(
            Icons.dashboard,
            "Dashboard",
            onTap: () => Navigator.pop(context),
          ),

          _drawerItem(
            Icons.qr_code_2,
            "Generate QR",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GenerateQRScreen()),
              );
            },
          ),

          _drawerItem(
            Icons.collections,
            "QR Gallery",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrGalleryScreen()),
              );
            },
          ),

          // 💡 NEW: User List Option
          _drawerItem(
            Icons.group,
            "User List",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserListScreen(),
                ), // الانتقال للشاشة الجديدة
              );
            },
          ),

          const Divider(color: Colors.white30),
          _drawerItem(
            Icons.logout,
            "Logout",
            onTap: () {
              logoutAdmin();
            },
          ),
        ],
      ),
    );
  }

  // Helper for Drawer items
  Widget _drawerItem(IconData icon, String label, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      drawer: Drawer(child: _buildDrawerContent()),

      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Dashboard Overview",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),

                const SizedBox(height: 40),

                // 💡 لوحة البطاقات (Wrap) - تعرض الإحصائيات مباشرة
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    // 💡 NEW CARD: Total Scans
                    DashboardCard(
                      label: "Total Scans",
                      value: logsCount.toString(), // يتم تحديثها من API
                      icon: Icons.scanner,
                    ),
                    DashboardCard(
                      label: "Fake Detections",
                      value: fake.toString(), // يتم تحديثها من API
                      icon: Icons.warning_amber_rounded,
                    ),
                    DashboardCard(
                      label: "Products",
                      value: products.toString(), // يتم تحديثها من API
                      icon: Icons.qr_code,
                    ),
                    DashboardCard(
                      label: "Users",
                      value: usersCount.toString(), // يتم تحديثها من API
                      icon: Icons.group,
                    ),
                    DashboardCard(
                      label: "Admins",
                      value: admins.toString(),
                      icon: Icons.person,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // 💡 Recent Activity Section
                SizedBox(
                  width: MediaQuery.of(context).size.width > 600
                      ? 600
                      : MediaQuery.of(context).size.width * 0.9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Recent Activity",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Activity List
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.light,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: logsList.length,
                          itemBuilder: (_, i) {
                            final item = logsList[i] as Map<String, dynamic>;

                            // Extract detailed info from new log structure
                            final actionType = item["action_type"] ?? "N/A";
                            final userEmail = item["user_email"] ?? "System";
                            final timestamp =
                                item["timestamp"] ??
                                DateTime.now().toIso8601String();
                            final status = item["scan_status"] ?? "";
                            final message =
                                item["message"] ?? "No details available.";

                            return ActivityItem(
                              id: actionType,
                              action:
                                  (status.isNotEmpty && status != "N/A"
                                      ? "($status) "
                                      : "") +
                                  message,
                              time: timeAgo(timestamp),
                              userEmail: userEmail,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------- CARD REMAINS THE SAME ----------
class DashboardCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isSmall;

  const DashboardCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;

    final cardWidth = isSmallScreen
        ? (screenWidth / 2) - 30
        : isSmall
        ? 160.0
        : 180.0;

    final actualCardWidth = isSmall ? 160.0 : cardWidth;

    final iconSize = isSmall ? 28.0 : 40.0;
    final valueSize = isSmall ? 22.0 : 28.0;

    return Container(
      width: actualCardWidth,
      height: isSmall ? 100 : 150,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.mid,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: iconSize, color: AppColors.dark),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.dark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// 💡 MODIFIED: ActivityItem to show user email and detailed message
class ActivityItem extends StatelessWidget {
  final String id; // Action Type
  final String action; // Full Message
  final String time;
  final String userEmail;

  const ActivityItem({
    super.key,
    required this.id,
    required this.action,
    required this.time,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color based on action type/scan status
    Color color = AppColors.dark;
    if (id == "QR_GENERATED" || action.contains("AUTHENTIC")) {
      color = Colors.green;
    } else if (action.contains("COUNTERFEIT") || id.contains("FAILED")) {
      color = Colors.red;
    } else if (id.contains("LOGIN") || id.contains("SIGNUP")) {
      color = Colors.blue;
    }

    return SizedBox(
      width: double.infinity,
      child: ListTile(
        leading: Icon(Icons.circle, size: 10, color: color),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$id by ${userEmail.split('@')[0]}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),
            Text(
              action,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        trailing: Text(
          time,
          style: const TextStyle(color: Colors.black45, fontSize: 12),
        ),
      ),
    );
  }
}

// =========================================================
// 💡 NEW SCREEN: User List Screen for Admin
// =========================================================
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<dynamic> users = [];
  bool loading = true;
  String error = "";

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      users = await ApiService.fetchUsers();
      if (users.isEmpty) {
        error = "No users found or failed to fetch.";
      }
    } catch (e) {
      error = "An error occurred while fetching users: $e";
      print(error);
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 1100 ? 1100.0 : screenWidth * 0.95;

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text(
          "Registered Users",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.dark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: loading
              ? const CircularProgressIndicator()
              : error.isNotEmpty
              ? Text(
                  error,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 50,
                        dataRowHeight: 65,
                        columnSpacing: 40,
                        border: TableBorder.all(
                          color: Colors.black12,
                          width: 0.5,
                        ),
                        headingRowColor: MaterialStateProperty.all(
                          AppColors.mid.withOpacity(0.5),
                        ),
                        columns: const [
                          DataColumn(label: Text("Name")),
                          DataColumn(label: Text("Email")),
                          DataColumn(label: Text("Phone Number")),
                          DataColumn(label: Text("Total Scans")),
                          // 💡 يمكن إضافة أعمدة أخرى هنا مثل تاريخ التسجيل
                        ],
                        rows: users.map((u) {
                          return DataRow(
                            cells: [
                              DataCell(Text(u["name"] ?? "N/A")),
                              DataCell(Text(u["email"] ?? "N/A")),
                              DataCell(Text(u["phone_number"] ?? "N/A")),
                              DataCell(
                                Text(u["scan_count"]?.toString() ?? "0"),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
