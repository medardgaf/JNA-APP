// lib/screens/reunions/reunion_presence_screen.dart
import 'package:flutter/material.dart';
import '../../services/reunion_service.dart';

class ReunionPresenceScreen extends StatefulWidget {
  final int reunionId;
  const ReunionPresenceScreen({super.key, required this.reunionId});

  @override
  State<ReunionPresenceScreen> createState() => _ReunionPresenceScreenState();
}

class _ReunionPresenceScreenState extends State<ReunionPresenceScreen> {
  List<Map<String, dynamic>> presences = [];
  bool loading = true;
  String? error;

  // map membre_id -> statut
  final Map<int, String> _changes = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
      presences = [];
      _changes.clear();
    });

    try {
      final res = await ReunionService.listPresence(widget.reunionId);
      if (res["success"] == true) {
        final raw = res["data"] ?? [];
        // normalize to List<Map<String,dynamic>>
        presences = List<Map<String, dynamic>>.from(
            raw.map((e) => Map<String, dynamic>.from(e)));
      } else {
        error = res["message"] ?? "Erreur serveur";
      }
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  String _currentStatusFor(Map<String, dynamic> p) {
    // statut from server (string) or from local changes
    final memberIdRaw = p['membre_id'];
    final memberId =
        (memberIdRaw is int) ? memberIdRaw : int.tryParse('$memberIdRaw') ?? 0;
    if (_changes.containsKey(memberId)) return _changes[memberId]!;
    final s = p['statut'];
    return s?.toString() ?? 'absent';
  }

  void _setStatus(int membreId, String statut) {
    _changes[membreId] = statut;
    setState(() {});
  }

  Future<void> _saveAll() async {
    if (_changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aucune modification à enregistrer")));
      return;
    }

    final updates = _changes.entries
        .map((e) => {"membre_id": e.key, "statut": e.value})
        .toList();

    try {
      final res = await ReunionService.bulkUpdatePresence(
          reunionId: widget.reunionId, updates: updates);
      if (res["success"] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Présences mises à jour")));
        await _load();
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

  Future<void> _toggleSingle(Map<String, dynamic> p, String newStatut) async {
    // Update single presence immediately (optimistic)
    final memberIdRaw = p['membre_id'];
    final membreId =
        (memberIdRaw is int) ? memberIdRaw : int.tryParse('$memberIdRaw') ?? 0;
    setState(() {
      _changes[membreId] = newStatut;
    });

    try {
      final res = await ReunionService.updatePresence(
          reunionId: widget.reunionId, membreId: membreId, statut: newStatut);
      if (res["success"] != true) {
        // rollback local change
        _changes.remove(membreId);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res["message"] ?? "Erreur")));
      } else {
        // success — reflect on the list by reloading or removing change marker
        _changes.remove(membreId);
        await _load();
      }
    } catch (e) {
      _changes.remove(membreId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Présences"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveAll,
              tooltip: "Enregistrer modifications"),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red)))
              : presences.isEmpty
                  ? const Center(child: Text("Aucune présence"))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: presences.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final p = presences[i];
                        final idRaw = p['membre_id'];
                        final membreId = (idRaw is int)
                            ? idRaw
                            : int.tryParse('$idRaw') ?? 0;
                        final name = p['nom_complet'] ??
                            "${p['nom'] ?? ''} ${p['prenoms'] ?? ''}";
                        final tel = p['telephone'] ?? '';
                        final statut = _currentStatusFor(p);

                        Color badgeColor;
                        IconData icon;
                        switch (statut) {
                          case 'present':
                            badgeColor = Colors.green;
                            icon = Icons.check_circle;
                            break;
                          case 'excuse':
                            badgeColor = Colors.orange;
                            icon = Icons.info;
                            break;
                          default:
                            badgeColor = Colors.red;
                            icon = Icons.cancel;
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: badgeColor,
                            child: Icon(icon, color: Colors.white),
                          ),
                          title: Text(name ?? "Membre"),
                          subtitle: Text(tel.toString()),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'present' ||
                                  v == 'absent' ||
                                  v == 'excuse') {
                                // for quick single update, call server
                                _toggleSingle(p, v);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                  value: 'present', child: Text('Présent')),
                              PopupMenuItem(
                                  value: 'absent', child: Text('Absent')),
                              PopupMenuItem(
                                  value: 'excuse', child: const Text('Excusé')),
                            ],
                            child: Chip(label: Text(statut.toUpperCase())),
                          ),
                        );
                      },
                    ),
    );
  }
}
