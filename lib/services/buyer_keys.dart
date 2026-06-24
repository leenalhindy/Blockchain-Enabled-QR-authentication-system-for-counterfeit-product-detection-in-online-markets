// lib/services/buyer_keys.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

class BuyerKeys {
  static final _storage = FlutterSecureStorage();

  static const String _prvKey = "USER_PRIVATE_KEY";
  static const String _pubKey = "USER_PUBLIC_KEY";

  // 🟢 جديد: مفتاح تخزين الاسم الكامل للمستخدم
  static const String _nameKey = "user_name";

  // ================= STORE KEYS =================
  static Future<void> storeKeys(
    String publicKeyB64,
    String privateKeyB64,
  ) async {
    await _storage.write(key: _pubKey, value: publicKeyB64);
    await _storage.write(key: _prvKey, value: privateKeyB64);
  }

  // ================= GET PUBLIC KEY =================
  static Future<String> getPublicKey() async {
    final pub = await _storage.read(key: _pubKey);
    if (pub == null) {
      throw Exception("Public key missing");
    }
    return pub;
  }

  // lib/services/buyer_keys.dart

  // ================= SIGN CHALLENGE =================
  static Future<String> signChallenge(String challenge) async {
    final prvB64 = await _storage.read(key: _prvKey);

    if (prvB64 == null) {
      throw Exception("Private key missing. Please log in again.");
    }

    try {
      // 1️⃣ فك seed (32 bytes)
      final seedBytes = base64Decode(prvB64.trim());
      if (seedBytes.length != 32) {
        throw Exception("Invalid private key seed length");
      }

      // 2️⃣ اشتق KeyPair من seed (✔️ الصحيح)
      final privateKey = ed.newKeyFromSeed(seedBytes);

      // 3️⃣ توقيع الـ challenge باستخدام privateKey (64 bytes)
      final signature = ed.sign(privateKey, utf8.encode(challenge));

      // 4️⃣ إرجاع Base64
      return base64Encode(signature);
    } catch (e) {
      throw Exception("Signing failed: $e");
    }
  }

  // 🟢 جديد: جلب اسم المستخدم من التخزين الآمن
  // ================= GET USER NAME =================
  static Future<String> getUserName() async {
    final name = await _storage.read(key: _nameKey);

    // الاسم مطلوب لبدء عملية الشراء (Purchase Start)
    if (name == null || name.isEmpty) {
      throw Exception("User name is missing. Please log in again.");
    }
    return name;
  }
}
