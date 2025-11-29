import 'package:flutter/material.dart';
import '../../services/autres_cotisation_service.dart';

class AddAutreCotisationScreen extends StatefulWidget {
  final int membreId;

  const AddAutreCotisationScreen({super.key, required this.membreId});

  @override
  State<AddAutreCotisationScreen> createState() =>
      _AddAutreCotisationScreenState();
}

class _AddAutreCotisationScreenState extends State<AddAutreCotisationScreen> {
  final montantController = TextEditingController();
  final commentaireController = TextEditingController();

  bool isLoading = false;

  void enregistrer() async {
    if (montantController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer un montant")),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await AutresCotisationService.ajouter(
      membreId: widget.membreId,
      montant: double.tryParse(montantController.text) ?? 0,
      commentaire: commentaireController.text,
    );

    setState(() => isLoading = false);

    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cotisation ajoutée avec succès")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Erreur")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter une cotisation")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: montantController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Montant",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: commentaireController,
              decoration: const InputDecoration(
                labelText: "Commentaire (optionnel)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : enregistrer,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Enregistrer"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
