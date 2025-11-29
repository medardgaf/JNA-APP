import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service pour gérer les catégories d'opérations financières.
///
/// Ce service communique avec l'API CategoryController.php pour ajouter,
/// modifier, supprimer et récupérer toutes les catégories.
class CategoryService {
  /// URL de base de l'API pour les catégories.
  static const String baseUrl =
      "https://k.jnatg.org/api/categories/CategoryController.php";

  /// Récupère la liste de toutes les catégories depuis l'API.
  ///
  /// Fait un appel API à `action=all`.
  /// Retourne une liste de dynamiques en cas de succès, ou une liste vide en cas d'erreur.
  static Future<List<Map<String, dynamic>>> getAll() async {
    final uri = Uri.parse("$baseUrl?action=all");
    try {
      final response = await http.get(uri);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          // On s'attend à ce que l'API renvoie une liste sous la clé "data"
          return List<Map<String, dynamic>>.from(data["data"] ?? []);
        } catch (e) {
          print("Erreur de décodage JSON (CategoryService.getAll): $e");
          // Tentative de nettoyage
          try {
            final body = response.body;
            final firstBrace = body.indexOf('{');
            if (firstBrace != -1) {
              final cleanBody = body.substring(firstBrace);
              final data = jsonDecode(cleanBody);
              return List<Map<String, dynamic>>.from(data["data"] ?? []);
            }
          } catch (_) {}

          print("Corps: ${response.body}");
          return [];
        }
      } else {
        // En cas d'erreur serveur, on retourne une liste vide pour éviter de planter l'UI
        return [];
      }
    } catch (e) {
      // En cas d'erreur réseau, on log l'erreur pour le débogage et on retourne une liste vide
      print("Erreur CategoryService.getAll: $e");
      return [];
    }
  }

  /// Ajoute une nouvelle catégorie via l'API.
  ///
  /// [nom] Le nom de la catégorie (ex: "Fonctionnement").
  /// [type] Le type de la catégorie (ex: "depense", "recette").
  /// Retourne un objet Map avec le succès de l'opération et un message.
  static Future<Map<String, dynamic>> add({
    required String nom,
    required String type,
  }) async {
    final uri = Uri.parse("$baseUrl?action=add");
    final body = jsonEncode({
      "nom": nom,
      "type": type,
    });

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      // On gère la réponse standardisée
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            "success": false,
            "message": "Erreur de format JSON (CategoryService.add)"
          };
        }
      } else {
        return {
          "success": false,
          "message":
              "Erreur serveur ${response.statusCode}: ${response.reasonPhrase}"
        };
      }
    } catch (e) {
      // En cas d'erreur réseau, on retourne un objet d'erreur standardisé
      return {"success": false, "message": "Erreur réseau : $e"};
    }
  }

  /// Met à jour une catégorie existante via l'API.
  ///
  /// [id] L'identifiant de la catégorie à modifier.
  /// [nom] Le nouveau nom de la catégorie.
  /// [type] Le nouveau type de la catégorie.
  /// Retourne un objet Map avec le succès de l'opération et un message.
  static Future<Map<String, dynamic>> update({
    required int id,
    required String nom,
    required String type,
  }) async {
    final uri = Uri.parse("$baseUrl?action=update&id=$id");
    final body = jsonEncode({
      "nom": nom,
      "type": type,
    });

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            "success": false,
            "message": "Erreur de format JSON (CategoryService.update)"
          };
        }
      } else {
        return {
          "success": false,
          "message":
              "Erreur serveur ${response.statusCode}: ${response.reasonPhrase}"
        };
      }
    } catch (e) {
      return {"success": false, "message": "Erreur réseau : $e"};
    }
  }

  /// Supprime une catégorie via l'API.
  ///
  /// [id] L'identifiant de la catégorie à supprimer.
  /// Retourne un objet Map avec le succès de l'opération et un message.
  static Future<Map<String, dynamic>> delete(int id) async {
    final uri = Uri.parse("$baseUrl?action=delete&id=$id");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            "success": false,
            "message": "Erreur de format JSON (CategoryService.update)"
          };
        }
      } else {
        return {
          "success": false,
          "message":
              "Erreur serveur ${response.statusCode}: ${response.reasonPhrase}"
        };
      }
    } catch (e) {
      return {"success": false, "message": "Erreur réseau : $e"};
    }
  }
}
