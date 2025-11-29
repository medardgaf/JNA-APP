import 'dart:convert';
import 'package:http/http.dart' as http;

class EventService {
  // Assure-toi que cette URL est correcte et accessible depuis ton téléphone/émulateur
  static const String base =
      "https://k.jnatg.org/api/events/EventController.php";

  // ---------------------------------------------------------------------------
  // GET ALL - Récupérer tous les événements (avec filtres optionnels)
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> getAll({
    String? type,
    String? q,
    String? dateFrom,
    String? dateTo,
  }) async {
    final params = {
      "action": "all",
      if (type != null && type.isNotEmpty) "type": type,
      if (q != null && q.isNotEmpty) "q": q,
      if (dateFrom != null && dateFrom.isNotEmpty) "date_from": dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) "date_to": dateTo,
    };

    try {
      final uri = Uri.parse(base).replace(queryParameters: params);
      final response = await http.get(uri);

      return _decodeResponse(response);
    } catch (e) {
      return {"success": false, "message": "Erreur connexion: $e"};
    }
  }

  // ---------------------------------------------------------------------------
  // GET ONE - Récupérer un seul événement
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> getOne(int id) async {
    try {
      final uri = Uri.parse(base).replace(queryParameters: {
        "action": "get",
        "id": id.toString(),
      });
      final response = await http.get(uri);

      return _decodeResponse(response);
    } catch (e) {
      return {"success": false, "message": "Erreur connexion: $e"};
    }
  }

  // ---------------------------------------------------------------------------
  // ADD - Ajouter un événement
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> add({
    required String titre,
    required String dateEvenement,
    String? description,
    String? lieu,
    String? type,
    String? couleur,
    int? createdBy,
  }) async {
    try {
      final uri = Uri.parse(base).replace(queryParameters: {"action": "add"});

      final body = {
        "titre": titre,
        "date_evenement": dateEvenement,
        "description": description ?? "",
        "lieu": lieu ?? "",
        "type": type ?? "Autre",
        "couleur": couleur ?? "#2196F3",
        if (createdBy != null) "created_by": createdBy,
      };

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      return _decodeResponse(response);
    } catch (e) {
      return {"success": false, "message": "Erreur connexion: $e"};
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE - Mettre à jour (Accepte une Map pour faciliter l'usage avec les formulaires)
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> update(
      Map<String, dynamic> eventData) async {
    try {
      // Vérification que l'ID est bien présent
      if (!eventData.containsKey('id')) {
        return {"success": false, "message": "ID de l'événement manquant"};
      }

      final uri = Uri.parse(base).replace(queryParameters: {
        "action": "update",
        "id": eventData['id'].toString(),
      });

      // On envoie tout l'objet eventData nettoyé
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(eventData),
      );

      return _decodeResponse(response);
    } catch (e) {
      return {"success": false, "message": "Erreur connexion: $e"};
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE - Supprimer
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> delete(int id) async {
    try {
      final uri = Uri.parse(base).replace(queryParameters: {
        "action": "delete",
        "id": id.toString(),
      });

      // Note: Le backend PHP accepte GET ou POST pour delete, on utilise GET ici
      final response = await http.get(uri);

      return _decodeResponse(response);
    } catch (e) {
      return {"success": false, "message": "Erreur connexion: $e"};
    }
  }

  // ---------------------------------------------------------------------------
  // MARK DONE - Marquer comme fait
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> markAsDone(int id) async {
    try {
      final uri = Uri.parse(base).replace(queryParameters: {
        "action": "mark_done",
        "id": id.toString(),
      });

      final response = await http.get(uri);

      return _decodeResponse(response);
    } catch (e) {
      return {"success": false, "message": "Erreur connexion: $e"};
    }
  }

  // ---------------------------------------------------------------------------
  // HELPER - Décodage sécurisé
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        print("Erreur de décodage JSON (EventService): $e");
        // Tentative de nettoyage
        try {
          final body = response.body;
          final firstBrace = body.indexOf('{');
          if (firstBrace != -1) {
            final cleanBody = body.substring(firstBrace);
            return jsonDecode(cleanBody);
          }
        } catch (_) {}

        print("Corps invalide: ${response.body}");
        return {
          "success": false,
          "message": "Erreur de format de réponse serveur (JSON invalide)."
        };
      }
    } else {
      return {
        "success": false,
        "message": "Erreur serveur: ${response.statusCode}"
      };
    }
  }
}
