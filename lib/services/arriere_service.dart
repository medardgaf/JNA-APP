// lib/services/arriere_service.dart
// VERSION FINALE — propre, sans erreurs, 100% compatible avec ton backend PHP

import '../utils/api.dart';
import 'package:flutter/foundation.dart';

class ArriereService {
  /* ========================
     GET ALL
     ======================== */
  static Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final res = await Api.dio.get(
        "/arrieres/ArriereController.php",
        queryParameters: {"action": "getAll"},
      );

      if (res.data is Map &&
          res.data["success"] == true &&
          res.data["data"] is List) {
        return List<Map<String, dynamic>>.from(res.data["data"]);
      }

      return [];
    } catch (e) {
      debugPrint("Erreur getAll: $e");
      return [];
    }
  }

  /* ========================
     ADD — Génère tous les arriérés
     ======================== */
  static Future<Map<String, dynamic>> add({
    required int membreId,
    required int mois,
    required int annee,
  }) async {
    try {
      final res = await Api.dio.post(
        "/arrieres/ArriereController.php?action=add",
        data: {
          "membre_id": membreId,
          "mois": mois,
          "annee": annee,
        },
      );

      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint("Erreur add: $e");
      return {"success": false, "message": "Erreur réseau"};
    }
  }

  /* ========================
     UPDATE
     ======================== */
  static Future<Map<String, dynamic>> update({
    required int id,
    required int membreId,
    required int mois,
    required int annee,
    String statut = "impaye",
    double montantPaye = 0.0,
  }) async {
    try {
      final res = await Api.dio.post(
        "/arrieres/ArriereController.php?action=update",
        data: {
          "id": id,
          "membre_id": membreId,
          "mois": mois,
          "annee": annee,
          "montant_paye": montantPaye,
          "statut": statut,
        },
      );

      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint("Erreur update: $e");
      return {"success": false, "message": "Erreur réseau"};
    }
  }

  /* ========================
     DELETE
     ======================== */
  static Future<bool> delete(int id) async {
    try {
      final res = await Api.dio.get(
        "/arrieres/ArriereController.php",
        queryParameters: {"action": "delete", "id": id},
      );

      return res.data["success"] == true;
    } catch (e) {
      debugPrint("Erreur delete: $e");
      return false;
    }
  }

  /* ========================
     RÉGULARISER
     ======================== */
  static Future<Map<String, dynamic>> regulariser({
    required int membreId,
    required double montant,
    required String dateOperation,
  }) async {
    try {
      final res = await Api.dio.post(
        "/arrieres/ArriereController.php?action=regulariser",
        data: {
          "membre_id": membreId,
          "montant": montant,
          "date_operation": dateOperation,
        },
      );

      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      debugPrint("Erreur regulariser: $e");
      return {"success": false, "message": "Erreur réseau"};
    }
  }
}
