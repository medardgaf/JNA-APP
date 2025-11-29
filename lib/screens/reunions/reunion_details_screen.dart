// lib/screens/reunions/reunion_details_screen.dart
import 'package:flutter/material.dart';
import '../../services/reunion_service.dart';
import 'reunion_presence_screen.dart';

class ReunionDetailsScreen extends StatefulWidget {
  final int reunionId;
  const ReunionDetailsScreen({super.key, required this.reunionId});

  @override
  State<ReunionDetailsScreen> createState() => _ReunionDetailsScreenState();
}

class _ReunionDetailsScreenState extends State<ReunionDetailsScreen> {
  Map<String, dynamic>? reunion;
  Map<String, dynamic>? stats;
  double participation = 0;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadFull();
  }

  Future<void> _loadFull() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ReunionService.detailsFull(widget.reunionId);
      if (res["success"] == true) {
        final data = res;
        // l'API renvoie reunion, stats, participation
        reunion = Map<String, dynamic>.from(data["reunion"] ?? {});
        stats = Map<String, dynamic>.from(data["stats"] ?? {});
        participation = (data["participation"] is num)
            ? (data["participation"] as num).toDouble()
            : double.tryParse('${data["participation"]}') ?? 0;
      } else {
        error = res["message"] ?? "Erreur serveur";
      }
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> _exportExcel() async {
    await ReunionService.exportExcel(widget.reunionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails réunion"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportExcel,
            tooltip: "Exporter présences (Excel)",
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: ListTile(
                          title: Text(
                            (reunion?['type_reunion'] ??
                                    reunion?['type'] ??
                                    'Réunion')
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              "Date : ${reunion?['date_reunion'] ?? reunion?['date_evenement'] ?? ''}\nOrdre du jour : ${reunion?['ordre_du_jour'] ?? ''}"),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          title: const Text("Statistiques"),
                          subtitle: Text(
                            "Présents : ${stats?['presents'] ?? 0}\n"
                            "Absents : ${stats?['absents'] ?? 0}\n"
                            "Excusés : ${stats?['excuses'] ?? 0}\n"
                            "Total : ${stats?['total'] ?? 0}",
                          ),
                          trailing: Text(
                            "${participation.toStringAsFixed(1)}%",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.list),
                              label: const Text("Voir présences"),
                              onPressed: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ReunionPresenceScreen(
                                            reunionId: widget.reunionId)));
                                // reload stats after returning
                                _loadFull();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text("Rafraîchir"),
                            onPressed: _loadFull,
                          )
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
