import 'dart:convert';
import 'package:http/http.dart' as http;

class CotisationService {
  static const String baseUrl = "https://k.jnatg.org/api";

  // --------------------------
  // GET /cotisations/membre/{id}
  // --------------------------
  static Future<Map<String, dynamic>> getCotisationsMembre(int membreId) async {
    final url = Uri.parse("$baseUrl/cotisations/membre/$membreId");

    final res = await http.get(url, headers: {
      "Content-Type": "application/json",
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception("Erreur serveur: ${res.body}");
  }

  // ----------------------------------
  // GET /cotisations/historique/{id}
  // ----------------------------------
  static Future<List<dynamic>> getHistoriqueMembre(int membreId) async {
    final url = Uri.parse("$baseUrl/cotisations/historique/$membreId");

    final res = await http.get(url, headers: {
      "Content-Type": "application/json",
    });

    final data = jsonDecode(res.body);

    if (data["success"] == true) {
      return data["historique"];
    } else {
      throw Exception(data["message"]);
    }
  }

  // -------------------------
  // POST /cotisations/payer
  // -------------------------
  static Future<Map<String, dynamic>> payerCotisation({
    required int membreId,
    required int annee,
    required int mois,
    required double montant,
  }) async {
    final url = Uri.parse("$baseUrl/cotisations/payer");

    final body = jsonEncode({
      "membre_id": membreId,
      "annee": annee,
      "mois": mois,
      "montant": montant,
    });

    final res = await http.post(url,
        headers: {"Content-Type": "application/json"}, body: body);

    final data = jsonDecode(res.body);

    return data;
  }

  static Future payer(
      {required int membreId,
      required int mois,
      required int annee,
      required double montant}) async {}

  static Future getCotisations(int id) async {}
}
