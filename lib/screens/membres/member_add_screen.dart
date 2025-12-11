import 'package:flutter/material.dart';
import '../../services/membre_service.dart';

class MemberAddScreen extends StatefulWidget {
  const MemberAddScreen({super.key});

  @override
  State<MemberAddScreen> createState() => _MemberAddScreenState();
}

class _MemberAddScreenState extends State<MemberAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final usernameCtrl = TextEditingController();
  final nomCtrl = TextEditingController();
  final prenomCtrl = TextEditingController();
  final telephoneCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  final roleCtrl = TextEditingController(text: 'membre');
  final statutCtrl = TextEditingController(text: 'actif');

  // NOUVEAU : Champ pour membre du bureau
  bool estMembreBureau = false;

  // CONTRÔLEURS POUR LES ARRÉRÉS
  final dateDebutArriereCtrl = TextEditingController();
  // SUPPRIMÉ : final statutArriereCtrl = TextEditingController(text: 'a_jour');
  // Ce contrôlait n'est plus nécessaire car le champ "statut des arriérés" n'existe pas dans l'API.
  final montantArriereCtrl = TextEditingController(text: '0.0');

  // Variable pour stocker la date sélectionnée
  DateTime? selectedDate;

  bool isLoading = false;

  // Méthode pour afficher le sélecteur de date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('fr', 'FR'), // Localisation française
      helpText: "Sélectionner une date",
      cancelText: "Annuler",
      confirmText: "Confirmer",
      fieldLabelText: "Date de début d'arriéré",
      fieldHintText: "AAAA-MM-JJ",
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        // Formatage de la date en AAAA-MM-JJ
        dateDebutArriereCtrl.text =
            "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    // CORRIGÉ : L'appel à la méthode MembreService.create a été modifié.
    // Le paramètre 'statutArriere' a été supprimé car il n'existe pas dans la méthode du service.
    final res = await MembreService.create(
      username: usernameCtrl.text,
      nom: nomCtrl.text,
      prenom: prenomCtrl.text,
      codePin: pinCtrl.text,
      telephone: telephoneCtrl.text,
      role: roleCtrl.text,
      statut: statutCtrl.text,
      estMembreBureau: estMembreBureau, // NOUVEAU
      // CHAMPS CONSERVÉS
      dateDebutArriere:
          dateDebutArriereCtrl.text.isEmpty ? null : dateDebutArriereCtrl.text,
      // SUPPRIMÉ : statutArriere: statutArriereCtrl.text,
      montantArriere: double.tryParse(montantArriereCtrl.text),
    );

    setState(() => isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Opération terminée")),
      );
      if (res["success"] == true) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un membre")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: usernameCtrl,
                decoration:
                    const InputDecoration(labelText: "Nom d'utilisateur"),
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              TextFormField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: "Nom"),
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              TextFormField(
                controller: prenomCtrl,
                decoration: const InputDecoration(labelText: "Prénom"),
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              TextFormField(
                controller: telephoneCtrl,
                decoration: const InputDecoration(labelText: "Téléphone"),
              ),
              TextFormField(
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Code PIN (4 chiffres)"),
                validator: (v) => v!.length != 4 ? "4 chiffres requis" : null,
              ),
              DropdownButtonFormField<String>(
                value: roleCtrl.text,
                decoration: const InputDecoration(labelText: "Rôle"),
                items: const [
                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                  DropdownMenuItem(
                      value: "tresorier", child: Text("Trésorier")),
                  DropdownMenuItem(
                      value: "secretaire", child: Text("Secrétaire")),
                  DropdownMenuItem(value: "membre", child: Text("Membre")),
                ],
                onChanged: (v) => roleCtrl.text = v!,
              ),
              DropdownButtonFormField<String>(
                value: statutCtrl.text,
                decoration: const InputDecoration(labelText: "Statut"),
                items: const [
                  DropdownMenuItem(value: "actif", child: Text("Actif")),
                  DropdownMenuItem(value: "inactif", child: Text("Inactif")),
                ],
                onChanged: (v) => statutCtrl.text = v!,
              ),

              // NOUVEAU : Checkbox pour membre du bureau
              const SizedBox(height: 10),
              CheckboxListTile(
                title: const Text("Membre du Bureau"),
                subtitle: const Text(
                  "Cochez si ce membre fait partie du bureau de l'association",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: estMembreBureau,
                onChanged: (val) {
                  setState(() {
                    estMembreBureau = val ?? false;
                  });
                },
                activeColor: Colors.blue,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 20),
              const Text("Gestion des Arriérés",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // CHAMP DE DATE
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: dateDebutArriereCtrl,
                    decoration: const InputDecoration(
                      labelText: "Date de début d'arriéré",
                      hintText: "AAAA-MM-JJ",
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return "Requis";
                      // Validation optionnelle du format de date
                      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
                        return "Format invalide (AAAA-MM-JJ)";
                      }
                      return null;
                    },
                  ),
                ),
              ),
              // SUPPRIMÉ : DropdownButtonFormField pour le statut des arriérés
              // Ce champ a été retiré car il n'est pas géré par l'API.
              TextFormField(
                controller: montantArriereCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Montant total des arriérés (FCFA)"),
                validator: (v) {
                  if (v!.isEmpty) return "Requis";
                  if (double.tryParse(v) == null) return "Montant invalide";
                  return null;
                },
              ),

              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text("Enregistrer"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
