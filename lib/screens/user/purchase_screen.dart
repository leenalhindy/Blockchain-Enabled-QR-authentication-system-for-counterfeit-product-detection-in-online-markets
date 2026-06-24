import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/services/buyer_keys.dart';
import 'package:my_app/theme/app_colors.dart';

class PurchaseScreen extends StatefulWidget {
  final Map<String, dynamic> productDetails;

  const PurchaseScreen({super.key, required this.productDetails});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  bool loading = false;
  int currentStep = 0;

  bool sellerVerified = false;
  bool transferDone = false;

  String purchaseMessage = "";

  Timer? statusTimer;
  Future<void> showBuyerConfirmation() async {
    final pid = widget.productDetails["product_id"];
    final seller = widget.productDetails["owner_name"] ?? "Unknown";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Purchase Request"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "You are about to request an ownership transfer for the product:",
            ),
            const SizedBox(height: 8),
            Text("Product ID: $pid"),
            const SizedBox(height: 8),
            Text("Current Owner: $seller"),
            const SizedBox(height: 12),
            const Text(
              "This request will be sent to the current owner, "
              "who must approve and digitally sign the transfer.",
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
            child: const Text("Send Request"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      handleStartPurchase();
    }
  }

  // ============================================================
  // STEP 1 — START PURCHASE (SEND CHALLENGE TO SELLER)
  // ============================================================
  Future<void> handleStartPurchase() async {
    setState(() => loading = true);

    final pid = widget.productDetails["product_id"];
    final buyerName = await BuyerKeys.getUserName();

    final result = await ApiService.purchaseStart(
      productId: pid,
      buyerName: buyerName,
    );

    setState(() => loading = false);

    if (result["status"] == "success") {
      setState(() {
        currentStep = 1;
        purchaseMessage =
            "📨 Challenge sent to seller. Waiting for approval...";
      });

      _startPollingSellerStatus();
    } else {
      setState(() {
        purchaseMessage = "❌ ${result["message"]}";
      });
    }
  }

  // ============================================================
  // POLLING — CHECK SELLER STATUS
  // ============================================================
  void _startPollingSellerStatus() {
    final pid = widget.productDetails["product_id"];

    statusTimer?.cancel();
    statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final res = await ApiService.checkSellerStatus(pid);

      if (res["status"] == "success" && res["seller_verified"] == true) {
        timer.cancel();
        setState(() {
          sellerVerified = true;
          currentStep = 2;
          purchaseMessage = "✅ Seller verified. You can complete the transfer.";
        });
      }
    });
  }

  // ============================================================
  // STEP 2 — COMPLETE OWNERSHIP TRANSFER
  // ============================================================
  Future<void> handleCompleteTransfer() async {
    setState(() => loading = true);

    final pid = widget.productDetails["product_id"];

    final result = await ApiService.purchaseComplete(productId: pid);

    setState(() => loading = false);

    if (result["status"] == "success") {
      setState(() {
        transferDone = true;
        currentStep = 3;
        purchaseMessage = "🎉 Ownership transferred successfully!";
      });
    } else {
      setState(() {
        purchaseMessage = "❌ ${result["message"]}";
      });
    }
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    super.dispose();
  }

  Widget successWidget() {
    return Column(
      children: const [
        Icon(Icons.check_circle, size: 110, color: Colors.green),
        SizedBox(height: 20),
        Text(
          "Ownership Transferred!",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = widget.productDetails["owner_name"] ?? "Unknown";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Product"),
        backgroundColor: AppColors.dark,
      ),
      backgroundColor: AppColors.light,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // CURRENT OWNER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.deep, width: 1.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Current Owner:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(ownerName, style: const TextStyle(fontSize: 17)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Stepper(
                currentStep: currentStep,
                controlsBuilder: (_, __) => const SizedBox.shrink(),
                steps: [
                  // STEP 1
                  Step(
                    title: const Text("Start Purchase"),
                    isActive: currentStep >= 0,
                    state: currentStep > 0
                        ? StepState.complete
                        : StepState.indexed,
                    content: ElevatedButton(
                      onPressed: loading || currentStep > 0
                          ? null
                          : showBuyerConfirmation,

                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Send Request to Seller"),
                    ),
                  ),

                  // STEP 2
                  Step(
                    title: const Text("Seller Approval"),
                    isActive: currentStep >= 1,
                    state: sellerVerified
                        ? StepState.complete
                        : StepState.indexed,
                    content: Text(
                      sellerVerified
                          ? "Seller approved the transfer."
                          : "Waiting for seller approval...",
                    ),
                  ),

                  // STEP 3
                  Step(
                    title: const Text("Complete Transfer"),
                    isActive: currentStep >= 2,
                    state: transferDone
                        ? StepState.complete
                        : StepState.indexed,
                    content: ElevatedButton(
                      onPressed: (!sellerVerified || loading)
                          ? null
                          : handleCompleteTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Transfer Ownership"),
                    ),
                  ),

                  // STEP 4
                  Step(
                    title: const Text("Success"),
                    isActive: currentStep >= 3,
                    state: transferDone
                        ? StepState.complete
                        : StepState.indexed,
                    content: successWidget(),
                  ),
                ],
              ),
            ),

            if (purchaseMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  purchaseMessage,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        purchaseMessage.startsWith("🎉") ||
                            purchaseMessage.startsWith("✅") ||
                            purchaseMessage.startsWith("📨")
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
