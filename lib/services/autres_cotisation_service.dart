import 'dart:convert';
import 'package:http/http.dart' as http;

class AutresCotisationService {
  static const String baseUrl =
      "https://k.jnatg.org/api/autres/AutreCotisationController.php";

  /// Ajouter une autre cotisation
  static Future<Map<String, dynamic>> ajouter({
    required int membreId,
    required double montant,
    String? commentaire,
  }) async {
    final url = Uri.parse("$baseUrl?action=add");

    final body = jsonEncode({
      "membre_id": membreId,
      "montant": montant,
      "commentaire": commentaire ?? "",
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    return jsonDecode(response.body);
  }

  /// Récupérer toutes les autres cotisations
  static Future<List<dynamic>> getAll() async {
    final url = Uri.parse("$baseUrl?action=all");
    final response = await http.get(url);

    final data = jsonDecode(response.body);
    if (data["success"] == true) {
      return data["data"];
    } else {
      return [];
    }
  }
}
