import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminInit {
  static const storage = FlutterSecureStorage();

  static Future<void> setupAdmin() async {
    // Check if admin already exists
    final exists = await storage.read(key: "admin_email");

    if (exists == null) {
      // Save default admin credentials
      await storage.write(key: "admin_email", value: "admin@qr.com");
      await storage.write(key: "admin_password", value: "123456");
    }
  }
}
