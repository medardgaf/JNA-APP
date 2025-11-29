import 'package:dio/dio.dart';
import 'dart:convert';
import '../utils/api.dart'; // Assurez-vous que le chemin vers votre configuration Dio est correct

class DashboardService {
  // CORRECTION CLÉ: Utiliser le chemin complet vers le fichier PHP
  // Ceci suppose que votre BaseUrl dans Api.dart est 'https://k.jnatg.org'
  static const url = "/dashboard/DashboardController.php";

  static Future<Map<String, dynamic>> loadStats(
      String role, int memberId) async {
    try {
      final response = await Api.dio.get(
        url,
        queryParameters: {
          "action": "stats",
          "role": role,
          "membre_id": memberId,
        },
      );

      final data = response.data;

      if (data == null) {
        throw Exception("Réponse vide du serveur.");
      }

      // Gérer le cas où Dio retourne déjà un Map ou nécessite le décodage
      // Gérer le cas où Dio retourne déjà un Map ou nécessite le décodage
      Map<String, dynamic> result;
      if (data is String) {
        try {
          result = Map<String, dynamic>.from(jsonDecode(data));
        } catch (e) {
          print("Erreur décodage DashboardService: $e");
          // Tentative de nettoyage
          try {
            final firstBrace = data.indexOf('{');
            if (firstBrace != -1) {
              final cleanBody = data.substring(firstBrace);
              result = Map<String, dynamic>.from(jsonDecode(cleanBody));
            } else {
              throw Exception("JSON invalide");
            }
          } catch (_) {
            throw Exception("Réponse serveur invalide (HTML détecté ?): $data");
          }
        }
      } else {
        result = Map<String, dynamic>.from(data);
      }

      if (result["success"] == true) {
        // Retourne toutes les données (y compris totaux, events, etc.)
        return result;
      } else {
        throw Exception(result['message'] ?? 'Erreur inconnue du serveur');
      }
    } on DioException catch (e) {
      String errorMessage = "Erreur de connexion au serveur.";

      if (e.response != null) {
        // Inclure le statut si disponible, important pour le débogage (e.g., 500)
        errorMessage =
            "Erreur serveur (${e.response?.statusCode}) : ${e.response?.statusMessage ?? e.response?.data}";
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage =
            "Délai de connexion dépassé. Vérifiez votre connexion Internet.";
      }

      // Lancer une exception pour être capturée par le FutureBuilder/Screen
      throw Exception(errorMessage);
    } catch (e) {
      // Pour les erreurs de décodage JSON ou autres erreurs inattendues
      throw Exception("Erreur de traitement des données: $e");
    }
  }
}
