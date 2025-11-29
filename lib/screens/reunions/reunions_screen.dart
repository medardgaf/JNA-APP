import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/reunion_service.dart';
import 'reunion_add_screen.dart';
import 'reunion_details_screen.dart';
import 'reunion_presence_screen.dart';

class ReunionsScreen extends StatefulWidget {
  const ReunionsScreen({super.key});

  @override
  State<ReunionsScreen> createState() => _ReunionsScreenState();
}

class _ReunionsScreenState extends State<ReunionsScreen> {
  List<dynamic> reunions = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ReunionService.getAll();
      if (res["success"] == true) {
        reunions = List<dynamic>.from(res["data"] ?? []);
      } else {
        error = res["message"] ?? "Erreur serveur";
      }
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Supprimer la réunion"),
            content:
                const Text("Voulez-vous vraiment supprimer cette réunion ?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(_, false),
                  child: const Text("Annuler")),
              TextButton(
                  onPressed: () => Navigator.pop(_, true),
                  child: const Text("Supprimer")),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    try {
      final res = await ReunionService.delete(id);
      if (res["success"] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Réunion supprimée")));
        _load();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res["message"] ?? "Erreur")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  Future<void> _exportExcel(int reunionId) async {
    final url = Uri.parse(
        "https://k.jnatg.org/api/reunions/export_excel.php?reunion_id=$reunionId");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir le fichier Excel")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Réunions"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ReunionAddScreen()));
          if (result == true) _load();
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red)))
              : reunions.isEmpty
                  ? const Center(child: Text("Aucune réunion"))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: reunions.length,
                        itemBuilder: (context, i) {
                          final r = reunions[i] as Map<String, dynamic>;
                          final idDynamic = r['id'];
                          final id = (idDynamic is int)
                              ? idDynamic
                              : int.tryParse('$idDynamic') ?? 0;
                          final type =
                              r['type_reunion'] ?? r['type'] ?? 'Réunion';
                          final date = r['date_reunion'] ??
                              r['date_evenement'] ??
                              r['date'] ??
                              '';
                          final titre = "$type • $date";

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(titre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(r['ordre_du_jour'] ?? ''),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'details') {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                ReunionDetailsScreen(
                                                    reunionId: id)));
                                    _load();
                                  } else if (value == 'presences') {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                ReunionPresenceScreen(
                                                    reunionId: id)));
                                    _load();
                                  } else if (value == 'export') {
                                    await _exportExcel(id);
                                  } else if (value == 'delete') {
                                    await _confirmDelete(id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'details', child: Text('Détails')),
                                  const PopupMenuItem(
                                      value: 'presences',
                                      child: Text('Présences')),
                                  const PopupMenuItem(
                                      value: 'export',
                                      child: Text('Exporter Excel')),
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Supprimer',
                                          style: TextStyle(color: Colors.red))),
                                ],
                              ),
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ReunionDetailsScreen(
                                            reunionId: id)));
                                _load();
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
