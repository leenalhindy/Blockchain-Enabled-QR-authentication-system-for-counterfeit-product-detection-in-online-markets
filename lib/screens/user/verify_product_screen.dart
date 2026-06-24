// lib/screens/user/verify_product_screen.dart

import 'package:my_app/screens/user/purchase_screen.dart';
import 'package:flutter/material.dart';
import 'package:my_app/theme/app_colors.dart';
import 'package:my_app/services/api_service.dart';
import 'qr_scanner_page.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VerifyProductScreen extends StatefulWidget {
  const VerifyProductScreen({super.key});

  @override
  State<VerifyProductScreen> createState() => _VerifyProductScreenState();
}

class _VerifyProductScreenState extends State<VerifyProductScreen> {
  final productIdCtrl = TextEditingController();
  bool loading = false;
  String verificationStatus = "";
  Map<String, dynamic>? productDetails;

  final storage = const FlutterSecureStorage();

  // ---------------- VERIFICATION LOGIC ----------------

  Future<void> handleVerification() async {
    final rawInput = productIdCtrl.text.trim();

    if (rawInput.isEmpty) {
      setState(() {
        verificationStatus = "Please enter or scan a Product ID.";
        productDetails = null;
      });
      return;
    }

    setState(() {
      loading = true;
      verificationStatus = "";
      productDetails = null;
    });

    Map<String, dynamic> productData;

    try {
      productData = jsonDecode(rawInput);
    } catch (e) {
      setState(() {
        loading = false;
        verificationStatus =
            "❌ Please scan the full QR code. Manual ID entry is not supported.";
      });
      return;
    }

    final userEmail = await storage.read(key: "user_email");
    if (userEmail != null) {
      productData["user_email"] = userEmail;
    }

    final result = await ApiService.verifyProduct(productData);

    if (result["status"] == "success") {
      setState(() {
        verificationStatus = "✅ Product is AUTHENTIC and VALID!";
        productDetails = result["payload"];
      });
    } else {
      setState(() {
        verificationStatus =
            "❌ COUNTERFEIT Detected! ${result['message'] ?? ''}";
      });
    }

    setState(() => loading = false);
  }

  // ---------------- BUILD PRODUCT DETAILS ----------------

  Widget _buildProductDetails(Map<String, dynamic> details) {
    final orderedKeys = [
      "product_id",
      "manufacturer_id",
      "owner_name",
      "owner_public_key",
      "category",
      "country",
      "nonce",
      "chain",
      "v",
      "pub",
      "sig",
    ];

    final displayDetails = orderedKeys.where((k) => details.containsKey(k)).map(
      (key) {
        String value = details[key]?.toString() ?? "N/A";

        if (key == "pub" || key == "sig" || key == "owner_public_key") {
          value = value.substring(0, 15) + "...";
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 160,
                child: Text(
                  key.toUpperCase() + ":",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(value)),
            ],
          ),
        );
      },
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Product Details",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
        const Divider(),
        ...displayDetails,
      ],
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final formWidth = screenWidth > 600 ? 500.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text(
          "Verify Product",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.dark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Container(
            width: formWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Scan Product QR Code",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 40),

                // SCAN BUTTON
                SizedBox(
                  height: 120,
                  child: OutlinedButton(
                    onPressed: () async {
                      final scannedCode = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QRScannerPage(),
                        ),
                      );

                      if (scannedCode != null &&
                          scannedCode is String &&
                          scannedCode.isNotEmpty) {
                        productIdCtrl.text = scannedCode;
                        handleVerification();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.deep, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 50,
                          color: AppColors.deep,
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Scan QR Code",
                          style: TextStyle(fontSize: 18, color: AppColors.dark),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Center(
                  child: Text(
                    "OR",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: productIdCtrl,
                  decoration: InputDecoration(
                    labelText: "Enter Product ID / Code",
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: loading ? null : handleVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "VERIFY",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                ),

                const SizedBox(height: 40),

                // RESULTS
                if (verificationStatus.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: verificationStatus.startsWith("✅")
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      verificationStatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: verificationStatus.startsWith("✅")
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (productDetails != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.light2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.deep.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductDetails(productDetails!),

                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: () async {
                              final buyerName =
                                  await storage.read(key: "user_name") ??
                                  "UnknownUser";

                              final updatedDetails = {
                                ...productDetails!,
                                "buyer_name": buyerName,

                                // 💥 أهم تعديل:
                                "owner_public_key":
                                    productDetails!["owner_public_key"],
                              };

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PurchaseScreen(
                                    productDetails: updatedDetails,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deep,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Continue to Buy",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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
}
