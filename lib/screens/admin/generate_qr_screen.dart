import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
// import 'package:my_app/services/admin_data.dart'; // ❌ تم إزالة الاستيراد
import 'package:my_app/theme/app_colors.dart';

class GenerateQRScreen extends StatefulWidget {
  const GenerateQRScreen({super.key});

  @override
  State<GenerateQRScreen> createState() => _GenerateQRScreenState();
}

class _GenerateQRScreenState extends State<GenerateQRScreen> {
  final versionCtrl = TextEditingController(text: "1.0");
  final idCtrl = TextEditingController();
  final manufacturerCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final chainCtrl = TextEditingController(text: "dev-chain");

  String? qrBase64;
  Map<String, dynamic>? qrData;
  bool loading = false;

  Future<void> handleGenerate() async {
    if (idCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Product ID is required")));
      return;
    }

    setState(() => loading = true);

    final product = {
      "v": versionCtrl.text.trim(),
      "product_id": idCtrl.text.trim(),
      "manufacturer_id": manufacturerCtrl.text.trim(),
      "category": categoryCtrl.text.trim(),
      "country": countryCtrl.text.trim(),
      "chain": chainCtrl.text.trim(),
    };

    final result = await ApiService.generateQR(product);

    if (result["qr_base64"] != null) {
      setState(() {
        qrBase64 = result["qr_base64"];
        qrData = result["payload"];
      });

      // ❌ تم إزالة: AdminData.addProductLog(idCtrl.text.trim());
      // الـ API يتولى تسجيل عملية التوليد
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result["message"] ?? "Error")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    // 💡 تحديد ما إذا كانت الشاشة عريضة (Desktop) أم ضيقة (Mobile)
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 700;

    // تحديد عرض نموذج الإدخال (عرض ثابت على الشاشات الكبيرة، عرض كامل على الهواتف)
    final formWidth = isLargeScreen ? 500.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text(
          "Generate QR Code",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // لضمان وضوح زر الرجوع
      ),

      body: Center(
        // 💡 لتوسيط النموذج على الشاشات الكبيرة
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: formWidth, // تطبيق عرض النموذج
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _input("Version", versionCtrl),
                _input("Product ID", idCtrl),
                _input("Manufacturer ID", manufacturerCtrl),
                _input("Category", categoryCtrl),
                _input("Country", countryCtrl),
                _input("Blockchain (chain URL)", chainCtrl),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : handleGenerate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ), // تحسين البادينغ
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Generate QR",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                if (qrBase64 != null) ...[
                  // 💡 توسيط رمز QR وتفاصيله
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "QR Code:",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Image.memory(
                          base64Decode(qrBase64!),
                          width: 250,
                          height: 250,
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          "Details:",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  // عرض تفاصيل الحمولة (Payload)
                  Container(
                    width: double.infinity, // يشغل العرض المتاح ضمن formWidth
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        // 💡 استخدام JsonEncoder لضمان عرض منسق وواضح
                        const JsonEncoder.withIndent('  ').convert(qrData),
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: "monospace",
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 💡 ويدجت مُساعد لحقل الإدخال
  Widget _input(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          TextField(
            controller: ctrl,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
