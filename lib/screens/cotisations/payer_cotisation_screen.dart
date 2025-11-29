import 'package:flutter/material.dart';
import '../../services/cotisation_service.dart';

class PayerCotisationScreen extends StatefulWidget {
  final int membreId;

  const PayerCotisationScreen({super.key, required this.membreId});

  @override
  State<PayerCotisationScreen> createState() => _PayerCotisationScreenState();
}

class _PayerCotisationScreenState extends State<PayerCotisationScreen> {
  int? selectedAnnee;
  int? selectedMois;

  double montant = 0;
  bool loading = false;
  String? errorMsg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payer une cotisation")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // -------------------------
            // ANNÉE
            // -------------------------
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "Année",
                border: OutlineInputBorder(),
              ),
              items: [
                for (int a = 2020; a <= DateTime.now().year; a++)
                  DropdownMenuItem(value: a, child: Text(a.toString()))
              ],
              onChanged: (v) {
                setState(() => selectedAnnee = v);
                _calculateMontant();
              },
            ),

            const SizedBox(height: 20),

            // -------------------------
            // MOIS
            // -------------------------
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "Mois",
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                12,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text("Mois ${i + 1}"),
                ),
              ),
              onChanged: (v) => setState(() => selectedMois = v),
            ),

            const SizedBox(height: 20),

            // -------------------------
            // MONTANT
            // -------------------------
            TextFormField(
              initialValue: montant == 0 ? "" : montant.toStringAsFixed(0),
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Montant",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            if (errorMsg != null)
              Text(errorMsg!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : _payer,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Valider le paiement"),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------
  // CALCUL MONTANT selon l’année
  // ---------------------------------------------
  void _calculateMontant() {
    if (selectedAnnee == null) return;

    setState(() {
      montant = selectedAnnee! < 2024 ? 200 : 250;
    });
  }

  // ---------------------------------------------
  // PAYER LA COTISATION
  // ---------------------------------------------
  Future<void> _payer() async {
    if (selectedAnnee == null || selectedMois == null) {
      setState(() => errorMsg = "Veuillez sélectionner mois et année.");
      return;
    }

    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
      final res = await CotisationService.payerCotisation(
        membreId: widget.membreId,
        annee: selectedAnnee!,
        mois: selectedMois!,
        montant: montant,
      );

      if (!mounted) return;

      if (res["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Paiement enregistré !")),
        );
        Navigator.pop(context);
      } else {
        setState(() => errorMsg = res["message"]);
      }
    } catch (e) {
      setState(() => errorMsg = "Erreur: $e");
    } finally {
      setState(() => loading = false);
    }
  }
}
