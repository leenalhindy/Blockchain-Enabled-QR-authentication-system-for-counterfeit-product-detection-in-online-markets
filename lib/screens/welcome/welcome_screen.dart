// lib/screens/welcome/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:my_app/screens/role/choose_role_screen.dart';
import 'package:my_app/theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // 💡 تحديد أقصى عرض للمحتوى في الشاشات العريضة لتظهر كتطبيق موبايل في المنتصف
    final double maxContentWidth = screenWidth > 600 ? 500 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.light,
      body: Stack(
        children: [
          // 1. الموجة العلوية (يجب أن تغطي العرض كاملاً)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                height: screenHeight * 0.40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6E57A5), Color(0xFFA795D9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // 2. عنوان التطبيق (QR Authenticator) - وضع يدوي ومحاذاة للوسط
          Positioned(
            top: 45,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "QR Authenticator",
                style: TextStyle(
                  fontSize: screenWidth < 600 ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // 3. محتوى الشاشة الرئيسي (الشعار والنصوص والزر)
          Center(
            // 💡 FIX 1: التوسيط الأفقي للمحتوى
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxContentWidth,
              ), // 💡 FIX 2: تحديد أقصى عرض للمحتوى
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight),
                  child: Column(
                    // التوزيع العمودي: الشعار والنص في الأعلى، والزر في الأسفل
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // التأكد من توسيط العناصر أفقياً
                    children: [
                      Column(
                        // Inner Column للمحتوى العلوي
                        children: [
                          // مسافة تعويضية للموجة والعنوان
                          SizedBox(height: screenHeight * 0.25),

                          // 4. الشعار الكبير في المنتصف
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: Image.asset(
                              "images/logo.png",
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox(height: 140),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // 5. العنوان الرئيسي
                          const Text(
                            "Welcome",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 6. العنوان الفرعي (italic)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              "Verify products easily and securely.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          const SizedBox(height: 5),

                          // 7. نص الوصف
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              "Your authenticity journey starts here.\nScan to check the integrity of your product.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ),

                          // مسافة إضافية لضبط التباعد
                          SizedBox(height: screenHeight * 0.05),
                        ],
                      ),

                      // 9. الزر في الأسفل
                      Padding(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChooseRoleScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 80,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Continue",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
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

// الكليبر الخاص بالموجة
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height);

    // الانحناء الأول (القوس الداخلي)
    var firstControlPoint = Offset(size.width * 0.25, size.height - 70);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // الانحناء الثاني (الإنحدار الخارجي)
    var secondControlPoint = Offset(size.width * 0.75, size.height + 20);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
