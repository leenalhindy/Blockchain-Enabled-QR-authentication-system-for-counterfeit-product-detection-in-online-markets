import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/services/buyer_keys.dart';
import 'package:my_app/theme/app_colors.dart';

class PendingSalesScreen extends StatefulWidget {
  const PendingSalesScreen({super.key});

  @override
  State<PendingSalesScreen> createState() => _PendingSalesScreenState();
}

class _PendingSalesScreenState extends State<PendingSalesScreen> {
  bool loading = true;
  List<dynamic> pendingSales = [];

  @override
  void initState() {
    super.initState();
    loadPendingSales();
  }

  // ======================================================
  // LOAD PENDING SALES
  // ======================================================
  Future<void> loadPendingSales() async {
    setState(() => loading = true);

    final res = await ApiService.getPendingSales();

    if (res["status"] == "success") {
      pendingSales = res["sales"];
    } else {
      pendingSales = [];
    }

    setState(() => loading = false);
  }

  // ======================================================
  // SELLER CONFIRMATION DIALOG (IMPORTANT)
  // ======================================================
  Future<void> showSellerConfirmation({
    required String productId,
    required String buyerName,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Ownership Transfer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "You are about to digitally sign an ownership transfer.",
            ),
            const SizedBox(height: 10),
            Text("Product ID: $productId"),
            Text("Buyer: $buyerName"),
            const SizedBox(height: 12),
            const Text(
              "This action uses your private key and is irreversible.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sign & Approve"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      acceptSale(productId);
    }
  }

  // ======================================================
  // ACCEPT SALE (SELLER FLOW)
  // ======================================================
  Future<void> acceptSale(String productId) async {
    setState(() => loading = true);

    try {
      // 1️⃣ Fetch challenge from server
      final challengeRes = await ApiService.getSellerChallenge(productId);

      if (challengeRes["status"] != "success") {
        throw Exception("Failed to fetch challenge");
      }

      final String challenge = challengeRes["challenge"];

      // 2️⃣ Sign challenge locally (private key never leaves device)
      final String signature = await BuyerKeys.signChallenge(challenge);

      // 3️⃣ Send signature to server
      final result = await ApiService.postSellerAccept(
        productId: productId,
        signature: signature,
      );

      if (result["status"] == "success") {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ Sale approved")));
        loadPendingSales();
      } else {
        throw Exception(result["message"] ?? "Approval failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ $e")));
    }

    setState(() => loading = false);
  }

  // ======================================================
  // UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Sales"),
        backgroundColor: AppColors.dark,
      ),
      backgroundColor: AppColors.light,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : pendingSales.isEmpty
          ? const Center(child: Text("No pending sales"))
          : ListView.builder(
              itemCount: pendingSales.length,
              itemBuilder: (_, i) {
                final item = pendingSales[i];
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    title: Text("Product: ${item["product_id"]}"),
                    subtitle: Text("Buyer: ${item["buyer_name"]}"),
                    trailing: ElevatedButton(
                      onPressed: () => showSellerConfirmation(
                        productId: item["product_id"],
                        buyerName: item["buyer_name"],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deep,
                      ),
                      child: const Text("Accept"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
