import 'autres_service.dart';
import 'mensuelles_service.dart';
import 'dons_service.dart';

class OperationsMerger {
  static Future<List<Map<String, dynamic>>> loadAll() async {
    final autres = await AutresService.getAll();
    final mensuelles = await MensuellesService.getAll();
    final dons = await DonsService.getAll();

    final List<Map<String, dynamic>> ops = [];

    // AUTRES
    for (final a in autres) {
      ops.add({
        "id": a["id"],
        "type": "Autre",
        "nom": "${a['nom']} ${a['prenoms']}",
        "membre_id": a["membre_id"],
        "montant": a["montant"],
        "date": a["created_at"],
        "comment": a["commentaire"] ?? "",
      });
    }

    // MENSUELLES
    for (final m in mensuelles) {
      ops.add({
        "id": m["id"],
        "type": "Mensuelle",
        "nom": "${m['nom']} ${m['prenoms']}",
        "membre_id": m["membre_id"],
        "montant": m["montant"],
        "date": m["created_at"] ?? m["mois"],
        "comment": "Cotisation de ${m['mois']}",
      });
    }

    // DONS
    for (final d in dons) {
      ops.add({
        "id": d["id"],
        "type": "Don",
        "nom": "${d['nom']} ${d['prenoms']}",
        "membre_id": d["membre_id"],
        "montant": d["montant"],
        "date": d["created_at"],
        "comment": d["description"] ?? "",
      });
    }

    // Tri par date desc
    ops.sort((a, b) => b["date"].compareTo(a["date"]));

    return ops;
  }
}
