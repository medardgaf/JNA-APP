import 'package:flutter/material.dart';
import '../../services/reunion_service.dart';

class ReunionAddScreen extends StatefulWidget {
  const ReunionAddScreen({super.key});

  @override
  State<ReunionAddScreen> createState() => _ReunionAddScreenState();
}

class _ReunionAddScreenState extends State<ReunionAddScreen> {
  final typeCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final ordreCtrl = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    typeCtrl.text = "Réunion";
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2090),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      dateCtrl.text = date.toString().split(" ")[0];
    }
  }

  Future<void> submit() async {
    if (typeCtrl.text.isEmpty || dateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Type et date sont obligatoires"),
        ),
      );
      return;
    }

    setState(() => loading = true);

    final res = await ReunionService.add({
      "type_reunion": typeCtrl.text,
      "date_reunion": dateCtrl.text,
      "ordre_du_jour": ordreCtrl.text,
      "created_by": 1, // à remplacer si tu gères l'admin connecté
    });

    setState(() => loading = false);

    if (!mounted) return;

    if (res["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Réunion créée avec succès")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Erreur inconnue")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer une réunion"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: typeCtrl,
              decoration: const InputDecoration(
                labelText: "Type de réunion",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Date de la réunion",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: pickDate,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ordreCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Ordre du jour",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Créer la réunion"),
            )
          ],
        ),
      ),
    );
  }
}
