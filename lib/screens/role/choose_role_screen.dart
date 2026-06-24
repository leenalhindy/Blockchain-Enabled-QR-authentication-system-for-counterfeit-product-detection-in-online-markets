import 'package:flutter/material.dart';
import 'package:my_app/widgets/app_header.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/screens/admin/admin_login_screen.dart';
import 'package:my_app/screens/user/user_signup_screen.dart';

class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.light,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppHeader(),

          // 💡 استخدام Expanded لتوزيع المحتوى المتبقي عمودياً
          Expanded(
            child: SingleChildScrollView(
              // للسماح بالتمرير على الشاشات الصغيرة
              child: ConstrainedBox(
                // لضمان أن المحتوى يشغل الارتفاع المتبقي ويسمح بالتوسيط الرأسي
                constraints: BoxConstraints(
                  minHeight:
                      screenHeight -
                      kToolbarHeight, // ارتفاع الشاشة - ارتفاع AppHeader التقريبي
                ),
                child: Column(
                  // 💡 توسيط المحتوى عمودياً
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20), // مسافة بسيطة من الأعلى
                    // العنوان
                    const Text(
                      "Choose Your Role",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),

                    const SizedBox(height: 50),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      // 💡 تحديد أقصى عرض للأزرار لتبدو جيدة على الشاشات الكبيرة
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          children: [
                            RoleButton(
                              label: "I am a User",
                              icon: Icons.person_outline,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UserSignUpScreen(),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 30),

                            RoleButton(
                              label: "I am an Admin",
                              icon: Icons.admin_panel_settings_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AdminLoginScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoleButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const RoleButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<RoleButton> createState() => _RoleButtonState();
}

class _RoleButtonState extends State<RoleButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,

        height: 58,
        // 💡 استخدام double.infinity لضمان أن الزر يأخذ أقصى عرض داخل الـ ConstrainedBox
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.mid,
          borderRadius: BorderRadius.circular(18),

          // shadow عند الضغط
          boxShadow: pressed
              ? [
                  BoxShadow(
                    color: AppColors.dark.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 24, color: AppColors.dark),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
