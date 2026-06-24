// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'buyer_keys.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:5000";

  static const _storage = FlutterSecureStorage();

  // -------------------- AUTH HELPERS --------------------

  static Future<String?> getAdminAuthToken() async {
    return await _storage.read(key: "admin_auth_token");
  }

  static Future<String?> _getAuthToken() async {
    String? adminToken = await _storage.read(key: "admin_auth_token");
    if (adminToken != null && adminToken.isNotEmpty) {
      return adminToken;
    }

    String? userToken = await _storage.read(key: "user_auth_token");
    if (userToken == null || userToken.isEmpty) {
      return null;
    }

    return userToken;
  }

  // -------------------- GENERIC POST --------------------

  static Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> data, {
    bool authRequired = false,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/$endpoint");
      final headers = {"Content-Type": "application/json"};

      if (authRequired) {
        final token = await _getAuthToken();
        if (token == null) {
          return {
            "status": "error",
            "message": "Authentication token missing. Please log in.",
          };
        }
        headers["Authorization"] = "Bearer $token";
      }

      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );

      final body = jsonDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {"status": "success", ...body};
      } else {
        return {
          "status": "error",
          "message": body["message"] ?? "An error occurred.",
        };
      }
    } catch (e) {
      return {"status": "error", "message": "Network error: $e"};
    }
  }

  // -------------------- GENERIC GET --------------------

  static Future<Map<String, dynamic>> _get(
    String endpoint, {
    bool authRequired = false,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/$endpoint");
      final headers = {"Content-Type": "application/json"};

      if (authRequired) {
        final token = await _getAuthToken();
        if (token == null) {
          return {
            "status": "error",
            "message": "Authentication token missing.",
          };
        }
        headers["Authorization"] = "Bearer $token";
      }

      final res = await http.get(url, headers: headers);
      final body = jsonDecode(res.body);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {"status": "success", ...body};
      } else {
        return {
          "status": "error",
          "message": body["message"] ?? "Error occurred.",
        };
      }
    } catch (e) {
      return {"status": "error", "message": "Network error: $e"};
    }
  }

  // =====================================================
  // 🟢 PURCHASE FLOW — FINAL LOGIC
  // =====================================================

  /// STEP 1 — Buyer starts purchase
  /// Server sends challenge to seller (buyer sees message only)
  static Future<Map<String, dynamic>> purchaseStart({
    required String productId,
    required String buyerName,
  }) async {
    final buyerPub = await BuyerKeys.getPublicKey();

    return await _post("purchase_start", {
      "product_id": productId,
      "buyer_name": buyerName,
      "buyer_public_key": buyerPub,
    });
  }

  /// STEP 2 — Buyer checks if seller approved
  static Future<Map<String, dynamic>> checkSellerStatus(
    String productId,
  ) async {
    return await _get("check_seller_status/$productId");
  }

  /// STEP 3 — Buyer completes ownership transfer
  /// (Only works if seller_verified = true)
  static Future<Map<String, dynamic>> purchaseComplete({
    required String productId,
  }) async {
    return await _post("purchase_complete", {"product_id": productId});
  }

  // ================= SELLER =================

  static Future<Map<String, dynamic>> getSellerChallenge(
    String productId,
  ) async {
    return await _get("seller_challenge/$productId", authRequired: true);
  }

  static Future<Map<String, dynamic>> postSellerAccept({
    required String productId,
    required String signature,
  }) async {
    final token = await _storage.read(key: "user_auth_token");

    if (token == null) {
      return {"status": "error", "message": "Seller must be logged in"};
    }

    final url = Uri.parse("$baseUrl/seller_accept");

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // 🔴 توكن اليوزر فقط
      },
      body: jsonEncode({"product_id": productId, "signature": signature}),
    );

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getPendingSales() async {
    return await _get("seller/pending", authRequired: true);
  }

  // -------------------- QR --------------------

  static Future<Map<String, dynamic>> verifyProduct(
    Map<String, dynamic> qrPayload,
  ) async {
    return await _post("verify_product", qrPayload);
  }

  static Future<Map<String, dynamic>> generateQR(
    Map<String, dynamic> product,
  ) async {
    return await _post("generate_qr", product, authRequired: true);
  }

  static Future<List<dynamic>> fetchQrRecords() async {
    final res = await _get("qr_records", authRequired: true);
    if (res["status"] == "success" && res["records"] is List) {
      return res["records"];
    }
    return [];
  }

  // -------------------- USERS --------------------

  static Future<Map<String, dynamic>> userSignup(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    final result = await _post("user_signup", {
      "name": name,
      "email": email,
      "password": password,
      "phone": phone,
    });

    if (result["status"] == "success") {
      await _storage.write(key: "user_auth_token", value: result["auth_token"]);
      await BuyerKeys.storeKeys(result["public_key"], result["private_key"]);
    }

    return result;
  }

  static Future<Map<String, dynamic>> userLogin(
    String email,
    String password,
  ) async {
    final result = await _post("user_login", {
      "email": email,
      "password": password,
    });

    if (result["status"] == "success") {
      await _storage.write(key: "user_auth_token", value: result["auth_token"]);
    }

    return result;
  }

  static Future<Map<String, dynamic>> changePassword(
    String email,
    String oldPw,
    String newPw,
  ) async {
    return await _post("change_password", {
      "email": email,
      "old_password": oldPw,
      "new_password": newPw,
    }, authRequired: true);
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    return await _post("user/update-profile", {
      "email": email,
      "first_name": firstName,
      "last_name": lastName,
      "phone_number": phoneNumber,
    }, authRequired: true);
  }

  // -------------------- ADMIN --------------------

  static Future<Map<String, dynamic>> adminLogin(
    String email,
    String password,
  ) async {
    return await _post("admin_login", {"email": email, "password": password});
  }

  static Future<Map<String, dynamic>> fetchDashboardStats() async {
    return await _get("admin/dashboard_stats", authRequired: true);
  }

  static Future<List<dynamic>> fetchUsers() async {
    final res = await _get("admin/users", authRequired: true);
    if (res["status"] == "success") {
      return res["users"];
    }
    return [];
  }
}
