import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl =
      "https://k.jnatg.org/api/auth/AuthController.php";

  static Future<Map<String, dynamic>> loginWithPin(String pin) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=login_pin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"code_pin": pin}),
      );

      // JSON sanitization
      String body = response.body;
      try {
        return jsonDecode(body);
      } catch (e) {
        // Try to extract JSON from response with PHP warnings
        final jsonStart = body.indexOf(RegExp(r'[{\[]'));
        if (jsonStart != -1) {
          body = body.substring(jsonStart);
          return jsonDecode(body);
        }
        rethrow;
      }
    } catch (e) {
      return {"success": false, "message": "Erreur réseau: ${e.toString()}"};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String username,
    required String telephone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nom": nom,
          "prenom": prenom,
          "username": username,
          "telephone": telephone,
        }),
      );

      // Debug: Print raw response
      print("=== RAW RESPONSE ===");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("===================");

      // Check for empty response
      if (response.body.isEmpty) {
        return {
          "success": false,
          "message":
              "Le serveur n'a pas renvoyé de réponse. Veuillez réessayer."
        };
      }

      // JSON sanitization
      String body = response.body;
      try {
        return jsonDecode(body);
      } catch (e) {
        print("JSON Decode Error: $e");
        // Try to extract JSON from response with PHP warnings
        final jsonStart = body.indexOf(RegExp(r'[{\[]'));
        if (jsonStart != -1) {
          body = body.substring(jsonStart);
          print("Extracted JSON: $body");
          return jsonDecode(body);
        }
        rethrow;
      }
    } catch (e) {
      print("Register Error: $e");
      return {"success": false, "message": "Erreur réseau: ${e.toString()}"};
    }
  }
}
