import 'package:flutter/material.dart';
import '../../services/membre_service.dart'; // Votre service existant
import 'member_details_screen.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> membres = [];
  List<Map<String, dynamic>> filtered = [];

  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      membres = await MembreService.getAll();
      filtered = List<Map<String, dynamic>>.from(membres);
    } catch (e) {
      error = e.toString();
    }

    if (mounted) setState(() => loading = false);
  }

  void filterMembers(String text) {
    text = text.toLowerCase().trim();
    filtered = membres.where((m) {
      return m["nom_complet"].toString().toLowerCase().contains(text);
    }).toList();
    setState(() {});
  }

  Future<void> _showDeleteConfirmationDialog(
      int memberId, int originalIndex) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Êtes-vous sûr de vouloir supprimer ce membre ?'),
                Text('Cette action est irréversible.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:
                  const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _confirmAndDelete(memberId, originalIndex);
              },
            ),
          ],
        );
      },
    );
  }

  // --- MODIFIÉ : Pour utiliser votre MembreService.delete() ---
  Future<void> _confirmAndDelete(int memberId, int originalIndex) async {
    // On sauvegarde le membre au cas où la suppression échoue
    final membreSupprime = filtered.removeAt(originalIndex);
    setState(() {}); // Met à jour l'UI immédiatement (optimistic update)

    try {
      // On appelle votre fonction qui renvoie une Map
      final result = await MembreService.delete(memberId);

      // On vérifie la clé 'success' dans la Map retournée
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Membre supprimé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Si le service renvoie une erreur, on restaure le membre
        setState(() {
          filtered.insert(originalIndex, membreSupprime);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Échec de la suppression.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // En cas d'erreur réseau, on restaure aussi le membre
      setState(() {
        filtered.insert(originalIndex, membreSupprime);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDismissibleMemberItem(Map<String, dynamic> membre, int index) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _showDeleteConfirmationDialog(int.parse(membre["id"]), index);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        elevation: 2,
        child: ListTile(
          leading: const Icon(Icons.person, color: Colors.blue),
          title: Text(
            membre["nom_complet"],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle:
              Text("Rôle : ${membre["role"]} • Statut : ${membre["statut"]}"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberDetailsScreen(
                  id: membre["id"],
                  membre: membre,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Liste des membres")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red)))
              : filtered.isEmpty
                  ? const Center(child: Text("Aucun membre trouvé"))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextField(
                            controller: searchCtrl,
                            onChanged: filterMembers,
                            decoration: InputDecoration(
                              hintText: "Rechercher un membre...",
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchCtrl.clear();
                                  filterMembers("");
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: load,
                            child: ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, i) =>
                                  _buildDismissibleMemberItem(filtered[i], i),
                            ),
                          ),
                        )
                      ],
                    ),
    );
  }
}
