import 'dart:convert';
import 'package:http/http.dart' as http;

class DonsService {
  static const String baseUrl =
      "https://k.jnatg.org/api/dons/DonController.php";

  /// Récupère la liste de tous les dons depuis l'API.
  /// Retourne une liste de données en cas de succès, ou une liste vide en cas d'échec.
  static Future<List<dynamic>> getAll() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl?action=all"));
      final jsonData = jsonDecode(response.body);
      if (jsonData["success"] == true) {
        return jsonData["data"];
      } else {
        // Affiche l'erreur de l'API pour le débogage
        print("Erreur API (getAll): ${jsonData["message"]}");
        return [];
      }
    } catch (e) {
      // Gère les erreurs de connexion ou autres
      print("Erreur réseau (getAll): $e");
      return [];
    }
  }

  /// Ajoute un nouveau don à la base de données via l'API.
  /// Retourne une carte (Map) contenant la clé "success" (booléen) et "message" (String).
  static Future<Map<String, dynamic>> add({
    required int membreId,
    required double montant,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=add"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "membre_id": membreId,
          "montant": montant,
          "description": description,
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

  /// Met à jour un don existant.
  static Future<Map<String, dynamic>> update({
    required int id,
    required double montant,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=update&id=$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "montant": montant,
          "description": description,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Erreur réseau: ${e.toString()}"};
    }
  }

  /// Supprime un don de la base de données.
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
