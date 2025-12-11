// services/membre_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MembreService {
  static const String baseUrl =
      "https://k.jnatg.org/api/membres/MembreController.php";
  static const String exportUrl =
      "https://k.jnatg.org/api/dashboard/export_membres.php";

  // =======================================================================
  //   MÉTHODES DE LECTURE (READ) - FORMAT NOUVEAU API
  // =======================================================================

  /// Récupère la liste de tous les membres actifs.
  static Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl?action=all"));

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          // NOUVEAU FORMAT : Accéder via data["membres"]
          if (jsonData['success'] == true && jsonData['data'] != null) {
            final data = jsonData['data'];
            if (data['membres'] != null) {
              return List<Map<String, dynamic>>.from(data['membres']);
            }
          }

          debugPrint(
              "Erreur MembreService.getAll: ${jsonData['message'] ?? 'Réponse invalide'}");
        } catch (e) {
          print("Erreur de décodage JSON (MembreService.getAll): $e");
          // Tentative de nettoyage
          try {
            final body = response.body;
            final firstBrace = body.indexOf('{');
            if (firstBrace != -1) {
              final cleanBody = body.substring(firstBrace);
              final jsonData = jsonDecode(cleanBody);
              if (jsonData['success'] == true && jsonData['data'] != null) {
                final data = jsonData['data'];
                if (data['membres'] != null) {
                  return List<Map<String, dynamic>>.from(data['membres']);
                }
              }
            }
          } catch (_) {}

          debugPrint("Corps: ${response.body}");
        }
      } else {
        debugPrint(
            "Erreur MembreService.getAll: Status code ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur réseau MembreService.getAll: $e");
    }
    return [];
  }

  /// Récupère les détails d'un membre spécifique par son ID.
  static Future<Map<String, dynamic>?> getOne(int id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl?action=get&id=$id"));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // NOUVEAU FORMAT : Accéder via data["membre"]
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];
          if (data['membre'] != null) {
            return Map<String, dynamic>.from(data['membre']);
          }
        }

        debugPrint(
            "Erreur MembreService.getOne: ${jsonData['message'] ?? 'Réponse invalide'}");
      } else {
        debugPrint(
            "Erreur MembreService.getOne: Status code ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur réseau MembreService.getOne: $e");
    }
    return null;
  }

  /// Récupère UNIQUEMENT le code PIN d'un membre via un endpoint sécurisé.
  static Future<String?> getMemberPin(int id) async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl?action=get_pin&id=$id"));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // NOUVEAU FORMAT : Accéder via data["code_pin"]
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final data = jsonData['data'];
          return data['code_pin'] as String?;
        }

        debugPrint(
            "Erreur MembreService.getMemberPin: ${jsonData['message'] ?? 'Réponse invalide'}");
      } else {
        debugPrint(
            "Erreur MembreService.getMemberPin: Status code ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur réseau MembreService.getMemberPin: $e");
    }
    return null;
  }

  // =======================================================================
  //   MÉTHODES DE CRÉATION ET DE MISE À JOUR (ADMIN)
  // =======================================================================

  /// Crée un nouveau membre.
  static Future<Map<String, dynamic>> create({
    required String username,
    required String nom,
    required String prenom,
    required String codePin,
    String? telephone,
    String? role,
    String? statut,
    bool? estMembreBureau,
    String? dateDebutArriere,
    double? montantArriere,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "nom": nom,
          "prenom": prenom,
          "code_pin": codePin,
          "telephone": telephone,
          "role": role,
          "statut": statut,
          "est_membre_bureau": estMembreBureau ?? false,
          "date_debut_arriere": dateDebutArriere,
          "montant_arriere": montantArriere,
        }),
      );

      final jsonData = jsonDecode(response.body);

      // NOUVEAU FORMAT
      if (jsonData['success'] == true) {
        return {
          "success": true,
          "message": jsonData['message'] ?? "Membre créé avec succès",
          "data": jsonData['data']
        };
      } else {
        return {
          "success": false,
          "message": jsonData['message'] ?? "Erreur lors de la création"
        };
      }
    } catch (e) {
      debugPrint("Erreur réseau MembreService.create: $e");
      return {"success": false, "message": "Erreur réseau: $e"};
    }
  }

  /// Met à jour les informations d'un membre (sauf le code PIN).
  static Future<Map<String, dynamic>> update({
    required int id,
    String? username,
    String? nom,
    String? prenom,
    String? telephone,
    String? role,
    String? statut,
    bool? estMembreBureau,
    String? dateDebutArriere,
    double? montantArriere,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=update"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id,
          if (username != null) "username": username,
          if (nom != null) "nom": nom,
          if (prenom != null) "prenom": prenom,
          if (telephone != null) "telephone": telephone,
          if (role != null) "role": role,
          if (statut != null) "statut": statut,
          if (estMembreBureau != null) "est_membre_bureau": estMembreBureau,
          if (dateDebutArriere != null) "date_debut_arriere": dateDebutArriere,
          if (montantArriere != null) "montant_arriere": montantArriere,
        }),
      );

      final jsonData = jsonDecode(response.body);

      // NOUVEAU FORMAT
      if (jsonData['success'] == true) {
        return {
          "success": true,
          "message": jsonData['message'] ?? "Membre mis à jour avec succès"
        };
      } else {
        return {
          "success": false,
          "message": jsonData['message'] ?? "Erreur lors de la mise à jour"
        };
      }
    } catch (e) {
      debugPrint("Erreur réseau MembreService.update: $e");
      return {"success": false, "message": "Erreur réseau: $e"};
    }
  }

  /// Met à jour le code PIN d'un membre.
  static Future<Map<String, dynamic>> updatePin({
    required int id,
    required String codePin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=update_pin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id,
          "code_pin": codePin,
        }),
      );

      final jsonData = jsonDecode(response.body);

      // NOUVEAU FORMAT
      if (jsonData['success'] == true) {
        return {
          "success": true,
          "message": jsonData['message'] ?? "Code PIN mis à jour avec succès"
        };
      } else {
        return {
          "success": false,
          "message":
              jsonData['message'] ?? "Erreur lors de la mise à jour du PIN"
        };
      }
    } catch (e) {
      debugPrint("Erreur réseau MembreService.updatePin: $e");
      return {"success": false, "message": "Erreur réseau: $e"};
    }
  }

  /// Supprime un membre.
  static Future<Map<String, dynamic>> delete(int id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=delete"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );

      final jsonData = jsonDecode(response.body);

      // NOUVEAU FORMAT
      if (jsonData['success'] == true) {
        return {
          "success": true,
          "message": jsonData['message'] ?? "Membre supprimé avec succès"
        };
      } else {
        return {
          "success": false,
          "message": jsonData['message'] ?? "Erreur lors de la suppression"
        };
      }
    } catch (e) {
      debugPrint("Erreur réseau MembreService.delete: $e");
      return {"success": false, "message": "Erreur réseau: $e"};
    }
  }

  // =======================================================================
  //   MÉTHODES SUPPLÉMENTAIRES
  // =======================================================================

  /// Met à jour le statut d'un membre (actif/inactif).
  static Future<Map<String, dynamic>> updateStatus(
      int id, bool isActive) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=update_status"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id,
          "is_active": isActive,
        }),
      );

      final jsonData = jsonDecode(response.body);

      // NOUVEAU FORMAT
      if (jsonData['success'] == true) {
        return {
          "success": true,
          "message": jsonData['message'] ?? "Statut mis à jour avec succès"
        };
      } else {
        return {
          "success": false,
          "message":
              jsonData['message'] ?? "Erreur lors de la mise à jour du statut"
        };
      }
    } catch (e) {
      debugPrint("Erreur réseau MembreService.updateStatus: $e");
      return {"success": false, "message": "Erreur réseau: $e"};
    }
  }

  /// Met à jour la date de début d'arriérés d'un membre.
  static Future<Map<String, dynamic>> updateDateDebutArriere({
    required int id,
    required String dateDebutArriere,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=update_date_arriere"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id,
          "date_debut_arriere": dateDebutArriere,
        }),
      );

      final jsonData = jsonDecode(response.body);

      // NOUVEAU FORMAT
      if (jsonData['success'] == true) {
        return {
          "success": true,
          "message":
              jsonData['message'] ?? "Date d'arriéré mise à jour avec succès"
        };
      } else {
        return {
          "success": false,
          "message": jsonData['message'] ??
              "Erreur lors de la mise à jour de la date d'arriéré"
        };
      }
    } catch (e) {
      debugPrint("Erreur réseau MembreService.updateDateDebutArriere: $e");
      return {"success": false, "message": "Erreur réseau: $e"};
    }
  }

  /// Met à jour le solde de crédit d'un membre.
  static Future<Map<String, dynamic>> updateSoldeCredit({
    required int id,
    required double montant,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl?action=update_solde_credit"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id,
          "montant": montant,
        }),
      );

      final jsonData = jsonDecode(response.body);

      // NOUVEAU FORMAT
      if (jsonData['success'] == true) {
        return {
          "success": true,
          "message":
              jsonData['message'] ?? "Solde de crédit mis à jour avec succès"
        };
      } else {
        return {
          "success": false,
          "message": jsonData['message'] ??
              "Erreur lors de la mise à jour du solde de crédit"
        };
      }
    } catch (e) {
      debugPrint("Erreur réseau MembreService.updateSoldeCredit: $e");
      return {"success": false, "message": "Erreur réseau: $e"};
    }
  }

  // =======================================================================
  //   EXPORT
  // =======================================================================

  /// Retourne l'URL pour exporter tous les membres en CSV
  ///
  /// Cette URL peut être utilisée avec url_launcher pour ouvrir le navigateur
  /// et télécharger le fichier CSV contenant tous les membres actifs
  static String getExportUrl() {
    return exportUrl;
  }

  /// Télécharge l'export des membres (retourne l'URL pour ouverture externe)
  ///
  /// Exemple d'utilisation avec url_launcher:
  /// ```dart
  /// import 'package:url_launcher/url_launcher.dart';
  ///
  /// final url = await MembreService.exportMembres();
  /// if (await canLaunchUrl(Uri.parse(url))) {
  ///   await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  /// }
  /// ```
  static Future<String> exportMembres() async {
    return exportUrl;
  }
}
