import 'package:flutter/material.dart';
import '../../services/membre_service.dart';
import '../../services/operations_services.dart';

class MemberEditScreen extends StatefulWidget {
  final Map<String, dynamic> membre;

  const MemberEditScreen({super.key, required this.membre});

  @override
  State<MemberEditScreen> createState() => _MemberEditScreenState();
}

class _MemberEditScreenState extends State<MemberEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _comptabiliser = true; // Par défaut, on comptabilise

  late TextEditingController usernameCtrl;
  late TextEditingController nomCtrl;
  late TextEditingController prenomCtrl;
  late TextEditingController telephoneCtrl;
  late TextEditingController roleCtrl;
  late TextEditingController statutCtrl;
  late TextEditingController dateDebutArriereCtrl;
  late TextEditingController montantArriereCtrl;
  late TextEditingController dateDebutCotisationCtrl;

  // NOUVEAU : Champ pour membre du bureau
  bool estMembreBureau = false;

  @override
  void initState() {
    super.initState();
    final m = widget.membre;

    final nomComplet = m['nom_complet']?.toString() ?? '';
    final parts = nomComplet.split(' ');
    final nomFallback = parts.isNotEmpty ? parts.first : '';
    final prenomFallback = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    usernameCtrl = TextEditingController(text: m['username']?.toString() ?? '');
    nomCtrl = TextEditingController(text: m['nom']?.toString() ?? nomFallback);
    prenomCtrl =
        TextEditingController(text: m['prenom']?.toString() ?? prenomFallback);
    telephoneCtrl =
        TextEditingController(text: m['telephone']?.toString() ?? '');
    roleCtrl = TextEditingController(text: m['role']?.toString() ?? 'membre');
    statutCtrl =
        TextEditingController(text: m['statut']?.toString() ?? 'actif');
    dateDebutArriereCtrl =
        TextEditingController(text: m['date_debut_arriere']?.toString() ?? '');
    montantArriereCtrl =
        TextEditingController(text: m['montant_arriere']?.toString() ?? '0.0');
    dateDebutCotisationCtrl = TextEditingController(
        text: m['date_debut_cotisation']?.toString() ?? '');

    // Initialiser estMembreBureau
    estMembreBureau =
        m['est_membre_bureau'] == true || m['est_membre_bureau'] == 1;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final res = await MembreService.update(
      id: int.parse(widget.membre['id'].toString()),
      nom: nomCtrl.text,
      prenom: prenomCtrl.text,
      telephone: telephoneCtrl.text,
      role: roleCtrl.text,
      statut: statutCtrl.text,
      estMembreBureau: estMembreBureau,
      dateDebutArriere:
          dateDebutArriereCtrl.text.isEmpty ? null : dateDebutArriereCtrl.text,
      montantArriere: double.tryParse(montantArriereCtrl.text),
    );

    setState(() => isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Opération terminée")),
      );
      if (res["success"] == true) Navigator.pop(context);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = dateDebutArriereCtrl.text.isNotEmpty
        ? DateTime.tryParse(dateDebutArriereCtrl.text) ?? DateTime.now()
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr'),
    );

    if (picked != null) {
      setState(() {
        dateDebutArriereCtrl.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _selectMonthYear(BuildContext context) async {
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;

    if (dateDebutCotisationCtrl.text.isNotEmpty) {
      final parts = dateDebutCotisationCtrl.text.split('-');
      if (parts.length == 2) {
        selectedYear = int.tryParse(parts[0]) ?? now.year;
        selectedMonth = int.tryParse(parts[1]) ?? now.month;
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        int tempYear = selectedYear;
        int tempMonth = selectedMonth;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sélectionner mois et année'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: tempYear,
                    decoration: const InputDecoration(
                      labelText: 'Année',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(10, (index) {
                      final year = now.year - 2 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => tempYear = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: tempMonth,
                    decoration: const InputDecoration(
                      labelText: 'Mois',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Janvier')),
                      DropdownMenuItem(value: 2, child: Text('Février')),
                      DropdownMenuItem(value: 3, child: Text('Mars')),
                      DropdownMenuItem(value: 4, child: Text('Avril')),
                      DropdownMenuItem(value: 5, child: Text('Mai')),
                      DropdownMenuItem(value: 6, child: Text('Juin')),
                      DropdownMenuItem(value: 7, child: Text('Juillet')),
                      DropdownMenuItem(value: 8, child: Text('Août')),
                      DropdownMenuItem(value: 9, child: Text('Septembre')),
                      DropdownMenuItem(value: 10, child: Text('Octobre')),
                      DropdownMenuItem(value: 11, child: Text('Novembre')),
                      DropdownMenuItem(value: 12, child: Text('Décembre')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => tempMonth = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final monthStr = tempMonth.toString().padLeft(2, '0');
                    dateDebutCotisationCtrl.text = '$tempYear-$monthStr';
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    setState(() {});
  }

  Future<void> _genererCotisationsInitiales() async {
    if (dateDebutCotisationCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord sélectionner une date de début'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la génération'),
        content: Text(
          'Voulez-vous générer automatiquement les cotisations de Janvier 2025 '
          'jusqu\'à ${dateDebutCotisationCtrl.text} pour ce membre ?\n\n'
          'Cette action créera toutes les cotisations mensuelles pour cette période.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Générer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      final result = await OperationService.genererCotisationsInitiales(
        int.parse(widget.membre['id'].toString()),
        dateDebutCotisationCtrl.text,
        comptabiliser: _comptabiliser,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Opération terminée'),
            backgroundColor:
                result['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier un membre")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _sectionCard("Informations personnelles", [
                _buildTextField(usernameCtrl, "Nom d'utilisateur",
                    icon: Icons.person),
                _buildTextField(nomCtrl, "Nom", icon: Icons.badge),
                _buildTextField(prenomCtrl, "Prénom", icon: Icons.badge),
                _buildTextField(telephoneCtrl, "Téléphone",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.length < 8 ? "Numéro invalide" : null),
                _buildDropdown(roleCtrl, "Rôle",
                    ["admin", "tresorier", "secretaire", "membre"]),
                _buildDropdown(statutCtrl, "Statut", ["actif", "inactif"]),
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
              ]),
              const SizedBox(height: 12),
              _sectionCard("Gestion des arriérés", [
                _buildDatePickerField(
                    dateDebutArriereCtrl, "Date de début (AAAA-MM-JJ)",
                    icon: Icons.calendar_today),
                _buildTextField(montantArriereCtrl, "Montant total (FCFA)",
                    icon: Icons.money,
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v!) == null
                        ? "Montant invalide"
                        : null),
              ]),
              const SizedBox(height: 12),
              _buildCotisationsInitialesSection(),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Enregistrer les modifications"),
                        onPressed: _submit,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label,
      {IconData? icon,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        validator: validator ?? (v) => v!.isEmpty ? "Requis" : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: "Ex: ${label.toLowerCase()}",
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(TextEditingController ctrl, String label,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () => _selectDate(context),
        child: AbsorbPointer(
          child: TextFormField(
            controller: ctrl,
            decoration: InputDecoration(
              labelText: label,
              hintText: "Sélectionner une date",
              prefixIcon: icon != null ? Icon(icon) : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      TextEditingController ctrl, String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: ctrl.text.isNotEmpty ? ctrl.text : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(_capitalize(e))))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            ctrl.text = v;
          }
        },
      ),
    );
  }

  Widget _buildCotisationsInitialesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cotisations initiales (Membres à jour)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pour les membres qui ont déjà payé avant la création de l\'app. '
              'Définissez jusqu\'à quelle date ils ont payé, le système générera '
              'automatiquement les cotisations depuis Janvier 2025.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Champ de sélection de date
            GestureDetector(
              onTap: () => _selectMonthYear(context),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: dateDebutCotisationCtrl,
                  decoration: InputDecoration(
                    labelText: 'Date de fin des cotisations (AAAA-MM)',
                    hintText: 'Ex: 2026-12',
                    prefixIcon: const Icon(Icons.calendar_month),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Checkbox pour comptabiliser ou non
            CheckboxListTile(
              title: const Text("Comptabiliser dans les recettes globales"),
              subtitle: const Text(
                "Si décoché, les cotisations seront visibles pour le membre mais n'augmenteront pas le solde en caisse.",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              value: _comptabiliser,
              onChanged: (val) {
                setState(() {
                  _comptabiliser = val ?? true;
                });
              },
              activeColor: Colors.blue,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 16),

            // Bouton pour générer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Générer les cotisations automatiquement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: isLoading ? null : _genererCotisationsInitiales,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Cette action ne fonctionne que pour les membres sans arriérés',
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : "${s[0].toUpperCase()}${s.substring(1)}";
}
