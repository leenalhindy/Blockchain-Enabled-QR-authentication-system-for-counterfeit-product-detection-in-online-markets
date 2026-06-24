// lib/screens/user/qr_scanner_page.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:my_app/theme/app_colors.dart';

class QRScannerPage extends StatelessWidget {
  const QRScannerPage({super.key});

  // 💡 ويدجت التراكب (الإطار الأبيض)
  Widget _buildOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.dark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // 🔑 FIX: استخدام Stack لوضع الماسح والإطار فوقه
      body: Stack(
        children: [
          // 1. الماسح الضوئي (في الخلفية)
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.noDuplicates,
              formats: const [BarcodeFormat.qrCode],
            ),

            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;

              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;

                if (code != null && code.isNotEmpty) {
                  print("✅ QR Code Detected! Code: $code");
                  Navigator.pop(context, code);
                  return;
                }
              }
            },
            // ❌ تم إزالة خاصية overlay
          ),

          // 2. التراكب (الإطار الأبيض في المقدمة)
          _buildOverlay(),
        ],
      ),
    );
  }
}
