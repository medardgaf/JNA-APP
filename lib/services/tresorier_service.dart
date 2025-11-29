import 'dart:convert';
import 'package:http/http.dart' as http;

class TresorierService {
  static const String baseUrl = 'https://k.jnatg.org/api';

  /// Récupère les données du dashboard trésorier
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/tresorier.php?action=dashboard'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Erreur serveur: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// Ajoute une opération
  static Future<Map<String, dynamic>> addOperation({
    required String type,
    required double montant,
    required String dateOperation,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/dashboard/tresorier.php?action=add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'type': type,
          'montant': montant,
          'date_operation': dateOperation,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Erreur serveur: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// Modifie une opération
  static Future<Map<String, dynamic>> updateOperation({
    required int id,
    required String type,
    required double montant,
    required String dateOperation,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/dashboard/tresorier.php?action=update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': id,
          'type': type,
          'montant': montant,
          'date_operation': dateOperation,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Erreur serveur: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// Supprime une opération
  static Future<Map<String, dynamic>> deleteOperation(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/tresorier.php?action=delete&id=$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Erreur serveur: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: $e'};
    }
  }

  /// URL pour l'export Excel
  static String getExportUrl() {
    return '$baseUrl/dashboard/export_tresorier.php';
  }
}
