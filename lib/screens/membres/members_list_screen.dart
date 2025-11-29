import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:kliv_app/screens/membres/member_add_screen.dart';
import '../../services/membre_service.dart';
import 'member_details_screen.dart';
import 'member_edit_screen.dart';

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
      final raw = await MembreService.getAll();

      membres = raw.map<Map<String, dynamic>>((m) {
        final id = int.tryParse(m["id"].toString()) ?? 0;
        return {
          "id": id,
          "nom_complet": (m["nom_complet"] ?? "").toString(),
          "nom": (m["nom"] ?? "").toString(),
          "prenom": (m["prenom"] ?? "").toString(),
          "role": (m["role"] ?? "").toString(),
          "telephone": (m["telephone"] ?? "").toString(),
          "username": (m["username"] ?? "").toString(),
          "statut": (m["statut"] ?? "").toString(),
          "montant_arriere":
              double.tryParse(m["montant_arriere"].toString()) ?? 0.0,
        };
      }).toList();

      filtered = List<Map<String, dynamic>>.from(membres);
    } catch (e) {
      error = e.toString();
    }

    if (mounted) setState(() => loading = false);
  }

  void filterMembers(String query) {
    query = query.toLowerCase().trim();
    filtered = membres.where((m) {
      return m["nom_complet"].toLowerCase().contains(query);
    }).toList();
    setState(() {});
  }

  Future<void> _deleteMember(int id, String nomComplet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text(
            "Êtes-vous sûr de vouloir supprimer le membre \"$nomComplet\" ? Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await MembreService.delete(id);

        if (result["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Membre \"$nomComplet\" supprimé avec succès"),
              backgroundColor: Colors.green,
            ),
          );
          await load(); // Recharger la liste
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Erreur: ${result["message"] ?? "Échec de la suppression"}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> exportToExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Membres'];

      sheet.appendRow([
        'ID',
        'Nom complet',
        'Nom',
        'Prénom',
        'Rôle',
        'Téléphone',
        'Username',
        'Statut',
        'Montant arriéré'
      ]);

      for (final m in filtered) {
        sheet.appendRow([
          m['id'],
          m['nom_complet'],
          m['nom'],
          m['prenom'],
          m['role'],
          m['telephone'],
          m['username'],
          m['statut'],
          m['montant_arriere'],
        ]);
      }

      // Vérification de la version Android (Uniquement si ce n'est pas le Web)
      bool storagePermissionNeeded = true;
      if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          storagePermissionNeeded =
              false; // Pas besoin de WRITE_EXTERNAL_STORAGE sur Android 13+
        }
      } else if (kIsWeb) {
        storagePermissionNeeded =
            false; // Pas de permission de stockage sur le Web
      } else {
        // iOS ou Desktop
        storagePermissionNeeded = false;
        // Note: Sur iOS on pourrait avoir besoin de permissions pour la galerie, mais pour Documents c'est souvent OK.
        // On simplifie pour l'instant.
      }

      if (!kIsWeb && storagePermissionNeeded) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permission de stockage refusée")),
          );
          return;
        }
      }

      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "L'export sur Web n'est pas encore supporté dans cette version.")),
        );
        return;
      }

      Directory? dir;
      if (Platform.isAndroid) {
        // Sur Android 13+, on préfère le dossier spécifique de l'app pour éviter les problèmes de droits
        // Sur les anciennes versions, on essaie d'écrire dans Download si possible, sinon app specific
        if (!storagePermissionNeeded) {
          dir =
              await getExternalStorageDirectory(); // /storage/emulated/0/Android/data/com.example.klivjna_rebuild/files
        } else {
          dir = Directory('/storage/emulated/0/Download');
          if (!await dir.exists()) {
            dir = await getExternalStorageDirectory();
          }
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Impossible d'accéder au dossier de stockage")),
        );
        return;
      }

      final filePath =
          "${dir.path}/membres_export_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final fileBytes = excel.encode();
      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Export réussi : $filePath"),
            duration: const Duration(seconds: 5)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur export : ${e.toString()}")),
      );
    }
  }

  Widget _buildMemberItem(Map<String, dynamic> m) {
    final int id = m["id"];
    final String nomComplet = m["nom_complet"];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.blue),
        title: Text(nomComplet,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Rôle : ${m["role"]} • Statut : ${m["statut"]}"),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange, size: 22),
              tooltip: "Modifier",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MemberEditScreen(membre: m),
                  ),
                ).then((_) => load());
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 22),
              tooltip: "Supprimer",
              onPressed: () => _deleteMember(id, nomComplet),
            ),
            IconButton(
              icon:
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
              tooltip: "Détails",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MemberDetailsScreen(id: id, membre: m),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des membres"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Exporter en Excel",
            onPressed: exportToExcel,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Ajouter un membre",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MemberAddScreen()),
              ).then((_) => load());
            },
          ),
        ],
      ),
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
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) =>
                                _buildMemberItem(filtered[i]),
                          ),
                        )
                      ],
                    ),
    );
  }
}
