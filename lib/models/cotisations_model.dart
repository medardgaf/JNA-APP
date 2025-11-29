class Cotisation {
  final int id;
  final int membreId;
  final int annee;
  final int mois;
  final double montantDu;
  final double montantPaye;
  final String statut;
  final String? dateRegularisation;
  final String createdAt;

  Cotisation({
    required this.id,
    required this.membreId,
    required this.annee,
    required this.mois,
    required this.montantDu,
    required this.montantPaye,
    required this.statut,
    this.dateRegularisation,
    required this.createdAt,
  });

  factory Cotisation.fromJson(Map<String, dynamic> json) {
    return Cotisation(
      id: int.parse(json["id"].toString()),
      membreId: int.parse(json["membre_id"].toString()),
      annee: int.parse(json["annee"].toString()),
      mois: int.parse(json["mois"].toString()),
      montantDu: double.parse(json["montant_du"].toString()),
      montantPaye: double.parse(json["montant_paye"].toString()),
      statut: json["statut"] ?? "",
      dateRegularisation: json["date_regularisation"],
      createdAt: json["created_at"] ?? "",
    );
  }
}
