import 'dart:convert';
import 'package:http/http.dart' as http;

class MensuellesService {
  static const String baseUrl =
      "https://k.jnatg.org/api/cotisations/CotisationController.php";

  /// Récupère toutes les cotisations mensuelles
  static Future<List<dynamic>> getAll() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl?action=all"));
      final jsonData = jsonDecode(response.body);
      if (jsonData["success"] == true) {
        return jsonData["data"];
      } else {
        print("Erreur API (getAll): ${jsonData["message"]}");
        return [];
      }
    } catch (e) {
      print("Erreur réseau (getAll): $e");
      return [];
    }
  }

  /// Ajouter une nouvelle cotisation mensuelle
  static Future<Map<String, dynamic>> add({
    required int membreId,
    required double montant,
    required String mois,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=add"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "membre_id": membreId,
          "montant": montant,
          "mois": mois,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      // En cas d'erreur réseau, on retourne une réponse d'erreur standardisée
      return {
        "success": false,
        "message":
            "Erreur réseau: Impossible de contacter le serveur. Détails: $e"
      };
    }
  }

  /// Met à jour une cotisation mensuelle existante
  static Future<Map<String, dynamic>> update({
    required int id,
    required double montant,
    required String mois,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=update&id=$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "montant": montant,
          "mois": mois,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Erreur réseau: ${e.toString()}"};
    }
  }

  /// Supprimer une cotisation mensuelle
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
