import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/cotisation_service.dart';

class CotisationAddScreen extends StatefulWidget {
  final VoidCallback onSaved;

  const CotisationAddScreen({super.key, required this.onSaved});

  @override
  State<CotisationAddScreen> createState() => _CotisationAddScreenState();
}

class _CotisationAddScreenState extends State<CotisationAddScreen> {
  final TextEditingController moisCtrl = TextEditingController();
  final TextEditingController anneeCtrl = TextEditingController();
  final TextEditingController montantCtrl = TextEditingController(text: "250");

  bool loading = false;
  String? error;

  Future<void> save() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      final resp = await CotisationService.payer(
        membreId: auth.id,
        mois: int.parse(moisCtrl.text.trim()),
        annee: int.parse(anneeCtrl.text.trim()),
        montant: double.parse(montantCtrl.text.trim()),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp["message"] ?? "Opération effectuée")),
      );

      if (resp["success"] == true) {
        widget.onSaved();
        Navigator.pop(context);
      } else {
        setState(() => error = resp["message"]);
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter une cotisation")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: moisCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Mois (1 à 12)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: anneeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Année (ex: 2024)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: montantCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Montant (ex: 250)"),
            ),
            const SizedBox(height: 15),
            if (error != null)
              Text(error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14)),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : save,
                child: loading
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
