import 'dart:convert';
import 'package:http/http.dart' as http;

class AutresService {
  static const String baseUrl =
      "https://k.jnatg.org/api/autres/AutreCotisationController.php";

  /// Récupère toutes les autres cotisations
  static Future<List<dynamic>> getAll() async {
    final response = await http.get(Uri.parse("$baseUrl?action=all"));
    final jsonData = jsonDecode(response.body);
    return jsonData["success"] == true ? jsonData["data"] : [];
  }

  /// Ajouter une nouvelle cotisation "autre"
  static Future<Map<String, dynamic>> add({
    required int membreId,
    required double montant,
    required String commentaire,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=add"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "membre_id": membreId,
          "montant": montant,
          "commentaire": commentaire,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      // En cas d'erreur réseau ou serveur, on retourne une réponse d'erreur standardisée
      return {
        "success": false,
        "message":
            "Erreur réseau: Impossible de contacter le serveur. Détails: $e"
      };
    }
  }

  /// Modifier une cotisation existante
  static Future<Map<String, dynamic>> update({
    required int id,
    required double montant,
    required String commentaire,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=update&id=$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "montant": montant,
          "commentaire": commentaire,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Erreur réseau: ${e.toString()}"};
    }
  }

  /// Supprimer une cotisation
  static Future<Map<String, dynamic>> delete(int id) async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl?action=delete&id=$id"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Erreur réseau: ${e.toString()}"};
    }
  }
}
