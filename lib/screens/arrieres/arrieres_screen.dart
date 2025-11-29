// lib/screens/arrieres/arrieres_screen.dart
// VERSION AMÉLIORÉE & CORRIGÉE 2025
// - Meilleure gestion d'erreurs
// - WhatsApp amélioré avec format international
// - UI/UX améliorée
// - Chargements optimisés
// - Validation renforcée

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/arriere_service.dart';
import '../../services/membre_service.dart';

class ArrieresScreen extends StatefulWidget {
  const ArrieresScreen({super.key});

  @override
  State<ArrieresScreen> createState() => _ArrieresScreenState();
}

class _ArrieresScreenState extends State<ArrieresScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _membres = [];
  List<Map<String, dynamic>> _arrieres = [];
  final Map<int, bool> _expandedStates = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final [membres, arrieres] = await Future.wait([
        MembreService.getAll(),
        ArriereService.getAll(),
      ]);

      if (!mounted) return;

      setState(() {
        _membres = membres;
        _arrieres = arrieres;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Erreur de chargement: ${e.toString()}";
      });
    }
  }

  /* ===========================
     FORM AJOUT / ÉDITION AMÉLIORÉ
     =========================== */
  Future<void> _showArriereForm({Map<String, dynamic>? item}) async {
    final formKey = GlobalKey<FormState>();
    int? _selectedMembreId;
    final _moisController = TextEditingController();
    final _anneeController = TextEditingController();

    // Pré-remplissage si édition
    if (item != null) {
      _selectedMembreId = int.tryParse(item['membre_id'].toString());
      _moisController.text = item['mois']?.toString() ?? '';
      _anneeController.text = item['annee']?.toString() ?? '';
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          item == null ? 'Nouvel arriéré' : 'Modifier l\'arriéré',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedMembreId,
                  decoration: const InputDecoration(
                    labelText: 'Membre *',
                    border: OutlineInputBorder(),
                  ),
                  items: _membres.map((membre) {
                    return DropdownMenuItem<int>(
                      value: int.parse(membre['id'].toString()),
                      child: Text(
                        "${membre['prenom']} ${membre['nom']}",
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => _selectedMembreId = value,
                  validator: (value) =>
                      value == null ? "Sélectionnez un membre" : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _moisController,
                        decoration: const InputDecoration(
                          labelText: 'Mois *',
                          border: OutlineInputBorder(),
                          hintText: '1-12',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Requis";
                          final mois = int.tryParse(value);
                          if (mois == null || mois < 1 || mois > 12) {
                            return "Mois invalide (1-12)";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _anneeController,
                        decoration: const InputDecoration(
                          labelText: 'Année *',
                          border: OutlineInputBorder(),
                          hintText: '2024',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Requis";
                          final annee = int.tryParse(value);
                          if (annee == null || annee < 2000 || annee > 2100) {
                            return "Année invalide";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final mois = int.parse(_moisController.text);
              final annee = int.parse(_anneeController.text);

              bool success;
              String message;

              try {
                if (item == null) {
                  final result = await ArriereService.add(
                    membreId: _selectedMembreId!,
                    mois: mois,
                    annee: annee,
                  );
                  success = result["success"] == true;
                  message = result["message"] ??
                      (success ? "Arriéré ajouté" : "Erreur");
                } else {
                  final result = await ArriereService.update(
                    id: int.parse(item['id'].toString()),
                    membreId: _selectedMembreId!,
                    mois: mois,
                    annee: annee,
                  );
                  success = result["success"] == true;
                  message = result["message"] ??
                      (success ? "Arriéré modifié" : "Erreur");
                }

                if (!mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );

                await _loadData();
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Erreur: ${e.toString()}"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(item == null ? "AJOUTER" : "MODIFIER"),
          ),
        ],
      ),
    );
  }

  /* ===========================
     RÉGULARISATION AMÉLIORÉE
     =========================== */
  Future<void> _showRegulariserDialog(int membreId, String nomComplet) async {
    final formKey = GlobalKey<FormState>();
    final _montantController = TextEditingController();
    final _dateController = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Régularisation"),
            Text("Pour $nomComplet",
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _montantController,
                decoration: const InputDecoration(
                  labelText: "Montant versé *",
                  border: OutlineInputBorder(),
                  prefixText: "FCFA ",
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Montant requis";
                  final montant = double.tryParse(value);
                  if (montant == null || montant <= 0) {
                    return "Montant invalide";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: "Date opération *",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    _dateController.text =
                        date.toIso8601String().split('T').first;
                  }
                },
                validator: (value) =>
                    value == null || value.isEmpty ? "Date requise" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              try {
                final result = await ArriereService.regulariser(
                  membreId: membreId,
                  montant: double.parse(_montantController.text),
                  dateOperation: _dateController.text,
                );

                if (!mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result["message"] ?? "Opération effectuée"),
                    backgroundColor:
                        result["success"] == true ? Colors.green : Colors.red,
                  ),
                );

                await _loadData();
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Erreur: ${e.toString()}"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("RÉGULARISER"),
          ),
        ],
      ),
    );
  }

  /* ===========================
     WHATSAPP AMÉLIORÉ
     =========================== */
  Future<void> _sendWhatsApp(
      Map<String, dynamic> membre, List<Map<String, dynamic>> arrieres) async {
    try {
      // Calcul du total
      double total = 0;
      final details = StringBuffer();

      for (final arriere in arrieres) {
        final montant = double.tryParse(arriere["montant_du"].toString()) ?? 0;
        total += montant;
        details.writeln(
            "• ${arriere['mois']}/${arriere['annee']} : ${montant.toStringAsFixed(0)} FCFA");
      }

      // Message formaté
      final message = """
Bonjour ${membre['prenom']} ${membre['nom']},

Voici le récapitulatif de vos arriérés :

${details.toString()}

📊 **Total à régulariser : ${total.toStringAsFixed(0)} FCFA**

Pour toute question, contactez-nous.

Cordialement,
Votre association
""";

      // Formatage du numéro de téléphone
      String telephone = (membre["telephone"] ?? "").toString();

      // Nettoyage du numéro
      telephone = telephone.replaceAll(RegExp(r'[+\s\-()]'), '').trim();

      // Vérification du format
      if (telephone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Aucun numéro de téléphone enregistré pour ce membre"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Ajout de l'indicatif Togo si absent
      if (!telephone.startsWith('228') && telephone.length == 8) {
        telephone = '228$telephone';
      }

      // Encodage URL
      final encodedMessage = Uri.encodeComponent(message);
      final url = "https://wa.me/$telephone?text=$encodedMessage";

      // Lancement WhatsApp
      final uri = Uri.parse(url);
      if (!await canLaunchUrl(uri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'ouvrir WhatsApp"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur WhatsApp: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /* ===========================
     SUPPRESSION AVEC CONFIRMATION
     =========================== */
  Future<void> _confirmDelete(Map<String, dynamic> arriere) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text(
          "Supprimer l'arriéré de ${arriere['mois']}/${arriere['annee']} ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("SUPPRIMER"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ArriereService.delete(int.parse(arriere['id'].toString()));
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Arriéré supprimé"),
            backgroundColor: Colors.green,
          ),
        );

        await _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /* ===========================
     INTERFACE UTILISATEUR
     =========================== */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Arriérés"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: "Actualiser",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showArriereForm(),
        child: const Icon(Icons.add),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Chargement des arriérés..."),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text("RÉESSAYER"),
            ),
          ],
        ),
      );
    }

    if (_membres.isEmpty || _arrieres.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Aucun arriéré enregistré",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return _buildGroupedList();
  }

  Widget _buildGroupedList() {
    // Regroupement des arriérés par membre
    final Map<int, List<Map<String, dynamic>>> groupedArrieres = {};

    for (final arriere in _arrieres) {
      final membreId = int.tryParse(arriere["membre_id"].toString()) ?? 0;
      groupedArrieres.putIfAbsent(membreId, () => []);
      groupedArrieres[membreId]!.add(arriere);
    }

    // Création des cartes par membre
    final List<Widget> memberCards = _membres.map((membre) {
      final membreId = int.tryParse(membre["id"].toString()) ?? 0;
      final arrieresDuMembre = groupedArrieres[membreId] ?? [];

      // Calcul du total
      final total = arrieresDuMembre.fold<double>(
        0,
        (sum, arriere) =>
            sum + (double.tryParse(arriere["montant_du"].toString()) ?? 0),
      );

      final hasArrieres = arrieresDuMembre.isNotEmpty;
      final isExpanded = _expandedStates[membreId] ?? false;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        child: ExpansionTile(
          key: Key('membre_$membreId'),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedStates[membreId] = expanded;
            });
          },
          leading: CircleAvatar(
            backgroundColor:
                hasArrieres ? Colors.orange.shade100 : Colors.green.shade100,
            child: Icon(
              hasArrieres ? Icons.warning : Icons.check_circle,
              color: hasArrieres ? Colors.orange : Colors.green,
            ),
          ),
          title: Text(
            "${membre['prenom']} ${membre['nom']}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${arrieresDuMembre.length} mois d'arriéré${arrieresDuMembre.length > 1 ? 's' : ''}",
              ),
              if (hasArrieres)
                Text(
                  "Total: ${total.toStringAsFixed(0)} FCFA",
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          trailing: hasArrieres
              ? _buildActionButtons(membre, arrieresDuMembre)
              : null,
          children: hasArrieres
              ? arrieresDuMembre
                  .map((arriere) => _buildArriereTile(arriere))
                  .toList()
              : [
                  const ListTile(
                      title: Text("Aucun arriéré",
                          style: TextStyle(color: Colors.grey)))
                ],
        ),
      );
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(children: memberCards),
    );
  }

  Widget _buildActionButtons(
      Map<String, dynamic> membre, List<Map<String, dynamic>> arrieres) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chat, color: Colors.green),
          onPressed: () => _sendWhatsApp(membre, arrieres),
          tooltip: "Envoyer rappel WhatsApp",
        ),
        IconButton(
          icon: const Icon(Icons.attach_money, color: Colors.blue),
          onPressed: () => _showRegulariserDialog(
            int.parse(membre['id'].toString()),
            "${membre['prenom']} ${membre['nom']}",
          ),
          tooltip: "Régulariser",
        ),
      ],
    );
  }

  Widget _buildArriereTile(Map<String, dynamic> arriere) {
    final montant = double.tryParse(arriere["montant_du"].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
        title: Text(
          "${arriere['mois']}/${arriere['annee']}",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text("Montant dû: ${montant.toStringAsFixed(0)} FCFA"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
              onPressed: () => _showArriereForm(item: arriere),
              tooltip: "Modifier",
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => _confirmDelete(arriere),
              tooltip: "Supprimer",
            ),
          ],
        ),
      ),
    );
  }
}
