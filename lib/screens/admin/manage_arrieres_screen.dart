import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/membre_service.dart';

class ManageArrieresScreen extends StatefulWidget {
  const ManageArrieresScreen({super.key});

  @override
  State<ManageArrieresScreen> createState() => _ManageArrieresScreenState();
}

class _ManageArrieresScreenState extends State<ManageArrieresScreen> {
  List<Map<String, dynamic>> _allMembers = [];
  bool _isLoading = true;
  bool _isUpdating = false;

  // CORRIGÉ : Le champ '_selectedMember' a été supprimé car il n'était pas utilisé.
  // Map<String, dynamic>? _selectedMember;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await MembreService.getAll();
      if (mounted) {
        setState(() {
          _allMembers = List<Map<String, dynamic>>.from(members);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de chargement: $e")),
        );
      }
    }
  }

  Future<void> _updateArriereDate(int memberId) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() => _isUpdating = true);

      try {
        // CORRIGÉ : L'appel à la méthode utilise maintenant les paramètres nommés requis.
        final result = await MembreService.updateDateDebutArriere(
            id: memberId,
            dateDebutArriere: DateFormat('yyyy-MM-dd').format(picked));

        setState(() => _isUpdating = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result["message"] ?? "Date mise à jour"),
              backgroundColor:
                  result["success"] == true ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() => _isUpdating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Arrérés'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  // CORRIGÉ : Ajout de 'const' pour optimiser les performances.
                  child: const Text(
                    'Cet écran permet de définir la date de début d\'arriérés pour chaque membre. Les cotisations seront calculées automatiquement à partir de cette date.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allMembers.length,
                    itemBuilder: (context, index) {
                      final member = _allMembers[index];
                      final hasArriereDate =
                          member['date_debut_arriere'] != null;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 2,
                        child: ListTile(
                          // CORRIGÉ : Réorganisation des arguments pour placer 'child' en premier.
                          leading: CircleAvatar(
                            child: Text(
                              member['nom']?.substring(0, 1).toUpperCase() ??
                                  '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            backgroundColor: Colors.red.shade100,
                          ),
                          title: Text(
                            '${member['nom']} ${member['prenom']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${member['id']}'),
                              Text(
                                hasArriereDate
                                    ? 'Date début arriérés: ${member['date_debut_arriere']}'
                                    : 'Date début arriérés: Non définie',
                                style: TextStyle(
                                  color: hasArriereDate
                                      ? Colors.black
                                      : Colors.red,
                                  fontWeight: hasArriereDate
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // CORRIGÉ : Ajout de 'const' pour optimiser les performances.
                              ElevatedButton(
                                onPressed: () =>
                                    _updateArriereDate(member['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade400,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Définir la date'),
                              ),
                            ],
                          ),
                          trailing: _isUpdating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle,
                                  color: Colors.green),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
