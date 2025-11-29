import 'dart:convert';
import 'package:http/http.dart' as http;

class OperationService {
  static const String baseUrl =
      "https://k.jnatg.org/api/operations/OperationController.php";

  // ==================== CRUD ====================

  /// Ajoute une nouvelle opération
  static Future<Map<String, dynamic>> add({
    required String type,
    required int categorieId,
    required int? membreId,
    required double montant,
    required String dateOperation,
    String? description,
  }) async {
    return _postRequest('add', {
      "type": type,
      "categorie_id": categorieId,
      "membre_id": membreId,
      "montant": montant,
      "date_operation": dateOperation,
      if (description != null) "description": description,
    });
  }

  /// Met à jour une opération existante
  static Future<Map<String, dynamic>> update({
    required int id,
    required String type,
    required int categorieId,
    required int? membreId,
    required double montant,
    required String dateOperation,
    String? description,
  }) async {
    return _postRequest('update', {
      "id": id,
      "type": type,
      "categorie_id": categorieId,
      "membre_id": membreId,
      "montant": montant,
      "date_operation": dateOperation,
      if (description != null) "description": description,
    });
  }

  /// Supprime une opération
  static Future<Map<String, dynamic>> delete(int id) async {
    return _postRequest('delete', {"id": id});
  }

  /// Récupère toutes les opérations
  static Future<Map<String, dynamic>> getAll({bool excludeDons = false}) async {
    final params = <String, String>{};
    if (excludeDons) {
      params['exclude_dons'] = 'true';
    }
    return _getRequest('all', params);
  }

  /// Récupère une opération par son ID
  static Future<Map<String, dynamic>> getById(int id) async {
    return _getRequest('details', {'id': id.toString()});
  }

  /// Récupère les statistiques financières
  static Future<Map<String, dynamic>> getStats() async {
    return _getRequest('stats');
  }

  /// Récupère les opérations par période
  static Future<Map<String, dynamic>> getByDateRange({
    required String startDate,
    required String endDate,
    bool excludeDons = true,
  }) async {
    return _getRequest('by_date', {
      'start': startDate,
      'end': endDate,
      'exclude_dons': excludeDons.toString(),
    });
  }

  /// Génère automatiquement les cotisations initiales pour un membre
  /// depuis Janvier 2025 jusqu'à la date spécifiée
  ///
  /// [membreId] ID du membre
  /// [dateDebutCotisation] Date au format 'YYYY-MM' (ex: '2026-12')
  static Future<Map<String, dynamic>> genererCotisationsInitiales(
      int membreId, String dateDebutCotisation,
      {bool comptabiliser = true}) async {
    return _postRequest('generer_cotisations_initiales', {
      'membre_id': membreId,
      'date_debut_cotisation': dateDebutCotisation,
      'comptabiliser': comptabiliser,
    });
  }

  static Future<Map<String, dynamic>> _getRequest(String action,
      [Map<String, String>? params]) async {
    try {
      final queryParams = {'action': action};
      if (params != null) {
        queryParams.addAll(params);
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      print("🔵 GET Request: $uri");

      final response = await http.get(uri);
      print("🟢 GET Response: ${response.statusCode} - ${response.body}");

      return _handleResponse(response);
    } catch (e) {
      print("🔴 GET Error: $e");
      return {
        "success": false,
        "message": "Erreur réseau : $e",
        "timestamp": DateTime.now().toIso8601String()
      };
    }
  }

  /// Méthode privée pour les requêtes POST
  static Future<Map<String, dynamic>> _postRequest(
      String action, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse("$baseUrl?action=$action");
      final body = jsonEncode(data);

      print("🔵 POST Request: $uri");
      print("📦 POST Body: $body");

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("🟢 POST Response: ${response.statusCode} - ${response.body}");
      return _handleResponse(response);
    } catch (e) {
      print("🔴 POST Error: $e");
      return {
        "success": false,
        "message": "Erreur réseau : $e",
        "timestamp": DateTime.now().toIso8601String()
      };
    }
  }

  /// Gestion uniforme des réponses
  static Map<String, dynamic> _handleResponse(http.Response response) {
    print("📨 Handling response: ${response.statusCode}");

    // Gestion des erreurs HTTP
    if (response.statusCode < 200 || response.statusCode >= 300) {
      print("🔴 HTTP Error: ${response.statusCode}");
      return {
        "success": false,
        "message": "Erreur HTTP ${response.statusCode}",
        "status_code": response.statusCode,
        "body": response.body,
        "timestamp": DateTime.now().toIso8601String()
      };
    }

    // Gestion du décodage JSON
    try {
      final decoded = jsonDecode(response.body);
      print("✅ JSON decoded successfully");
      return decoded;
    } catch (e) {
      print("🔴 JSON decode error: $e");
      print("📄 Raw response: ${response.body}");

      // Tentative de récupération si le JSON est mal formaté
      try {
        final body = response.body;
        final jsonStart = body.indexOf('{');
        if (jsonStart != -1) {
          final jsonString = body.substring(jsonStart);
          final decoded = jsonDecode(jsonString);
          print("🟡 JSON recovered after cleaning");
          return decoded;
        }
      } catch (e2) {
        print("🔴 JSON recovery failed: $e2");
      }

      return {
        "success": false,
        "message": "Erreur de format JSON dans la réponse",
        "raw_response": response.body,
        "timestamp": DateTime.now().toIso8601String()
      };
    }
  }
}
