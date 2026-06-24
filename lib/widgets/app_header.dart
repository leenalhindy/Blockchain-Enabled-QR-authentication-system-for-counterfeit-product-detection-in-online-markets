// lib/widgets/app_header.dart

import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // تم زيادة البادينغ العلوي لتعويض ارتفاع الموجة
      padding: const EdgeInsets.fromLTRB(25, 35, 25, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          // TEXT
          Text(
            "QR Authenticator",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C71B2),
            ),
          ),
          // تم إزالة الشعار الأيقوني الصغير
        ],
      ),
    );
  }
}
