import 'package:dio/dio.dart';
import 'dart:convert';
import '../utils/api.dart';

class MemberDashboardService {
  /// --------------------------
  /// Charger les stats du membre
  /// --------------------------
  static Future<Map<String, dynamic>> loadStats(int membreId) async {
    final url =
        "/dashboard/member.php?action=stats&role=membre&membre_id=$membreId";

    try {
      final response = await Api.dio.get<String>(url);

      if (response.data == null || response.data!.isEmpty) {
        throw Exception("Réponse vide du serveur.");
      }

      final decoded = jsonDecode(response.data!);

      if (decoded["success"] == true) {
        return Map<String, dynamic>.from(decoded);
      } else {
        throw Exception(decoded["message"] ?? "Erreur inconnue du serveur");
      }
    } catch (e) {
      throw Exception("Erreur chargement données membre : $e");
    }
  }

  /// --------------------------------------
  /// Charger toutes les opérations (ADMIN)
  /// --------------------------------------
  static Future<Map<String, dynamic>> loadAllAdmin() async {
    final url = "/dashboard/member.php?action=all&role=admin";

    try {
      final response = await Api.dio.get<String>(url);

      if (response.data == null || response.data!.isEmpty) {
        throw Exception("Réponse vide du serveur.");
      }

      final decoded = jsonDecode(response.data!);

      if (decoded["success"] == true) {
        return Map<String, dynamic>.from(decoded["data"]);
      } else {
        throw Exception(decoded["message"] ?? "Erreur serveur admin");
      }
    } catch (e) {
      throw Exception("Erreur chargement admin : $e");
    }
  }
}
