import 'dart:convert';
import 'package:http/http.dart' as http;

class ReunionService {
  static const String baseUrl =
      "https://k.jnatg.org/api/reunions/ReunionController.php";

  // ----------------------------------------------------------------------
  // GET ALL REUNIONS
  // ----------------------------------------------------------------------
  static Future<Map<String, dynamic>> getAll() async {
    final url = Uri.parse("$baseUrl?action=all");
    final r = await http.get(url);

    try {
      return jsonDecode(r.body);
    } catch (_) {
      return {"success": false, "message": "Format JSON invalide"};
    }
  }

  // ----------------------------------------------------------------------
  // GET DETAILS
  // ----------------------------------------------------------------------
  static Future<Map<String, dynamic>> getDetails(int id) async {
    final url = Uri.parse("$baseUrl?action=details&id=$id");
    final r = await http.get(url);

    try {
      return jsonDecode(r.body);
    } catch (_) {
      return {"success": false, "message": "Réponse JSON invalide"};
    }
  }

  // SERT À CHARGER DÉTAILS + STATS + PARTICIPATION
  static Future<Map<String, dynamic>> detailsFull(int id) async {
    return await getDetails(id);
  }

  // ----------------------------------------------------------------------
  // LISTE DES PRESENCES D'UNE RÉUNION
  // ----------------------------------------------------------------------
  static Future<Map<String, dynamic>> listPresence(int reunionId) async {
    final url = Uri.parse("$baseUrl?action=list_presence&id=$reunionId");
    final r = await http.get(url);

    try {
      return jsonDecode(r.body);
    } catch (e) {
      return {"success": false, "message": "Format JSON invalide"};
    }
  }

  // ----------------------------------------------------------------------
  // UPDATE PRESENCE INDIVIDUELLE
  // ----------------------------------------------------------------------
  static Future<Map<String, dynamic>> updatePresence({
    required int reunionId,
    required int membreId,
    required String statut,
  }) async {
    final url = Uri.parse("$baseUrl?action=update_presence");

    final body = {
      "reunion_id": reunionId,
      "membre_id": membreId,
      "statut": statut,
    };

    final r = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    try {
      return jsonDecode(r.body);
    } catch (e) {
      return {"success": false, "message": "Format JSON invalide"};
    }
  }

  // ----------------------------------------------------------------------
  // BULK UPDATE (plusieurs statuts en une fois)
  // ----------------------------------------------------------------------
  static Future<Map<String, dynamic>> bulkUpdatePresence({
    required int reunionId,
    required List<Map<String, dynamic>> updates,
  }) async {
    final url = Uri.parse("$baseUrl?action=bulk_update_presence");

    final body = {
      "reunion_id": reunionId,
      "updates": updates,
    };

    final r = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    try {
      return jsonDecode(r.body);
    } catch (e) {
      return {"success": false, "message": "JSON invalide"};
    }
  }

  // ----------------------------------------------------------------------
  // AJOUTER UNE REUNION
  // ----------------------------------------------------------------------
  static Future<Map<String, dynamic>> add(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl?action=add");

    final r = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    try {
      return jsonDecode(r.body);
    } catch (e) {
      return {"success": false, "message": "Erreur JSON"};
    }
  }

  // ----------------------------------------------------------------------
  // SUPPRESSION D'UNE REUNION
  // ----------------------------------------------------------------------
  static Future<Map<String, dynamic>> delete(int id) async {
    final url = Uri.parse("$baseUrl?action=delete&id=$id");
    final r = await http.get(url);

    try {
      return jsonDecode(r.body);
    } catch (e) {
      return {"success": false, "message": "JSON invalide"};
    }
  }

  // ----------------------------------------------------------------------
  // EXPORT EXCEL (ouvre un lien dans navigateur / chrome / share…)
  // ----------------------------------------------------------------------
  static Future<void> exportExcel(int reunionId) async {
    final url = "$baseUrl?action=export_excel&id=$reunionId";

    // Rien à gérer ici : tu peux ouvrir avec url_launcher si tu veux
    print("Téléchargement Excel : $url");
  }
}
