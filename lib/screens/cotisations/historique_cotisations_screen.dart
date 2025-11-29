import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/cotisation_service.dart';
import '../../models/cotisations_model.dart';
import 'package:intl/intl.dart';

class HistoriqueCotisationsScreen extends StatefulWidget {
  const HistoriqueCotisationsScreen({super.key});

  @override
  State<HistoriqueCotisationsScreen> createState() =>
      _HistoriqueCotisationsScreenState();
}

class _HistoriqueCotisationsScreenState
    extends State<HistoriqueCotisationsScreen> {
  bool loading = true;
  String? error;
  List<Cotisation> items = [];

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
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final raw = await CotisationService.getHistoriqueMembre(auth.id);

      items = raw
          .map((e) => Cotisation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      error = "Erreur : ${e.toString()}";
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des cotisations'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = items[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Mois : ${c.mois}/${c.annee}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text("Montant dû : ${c.montantDu} FCFA"),
                          Text("Montant payé : ${c.montantPaye} FCFA"),
                          const SizedBox(height: 6),
                          Text(
                            "Statut : ${c.statut.toUpperCase()}",
                            style: TextStyle(
                              color: c.statut == "paye"
                                  ? Colors.green
                                  : c.statut == "impaye"
                                      ? Colors.red
                                      : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                              "Créé le : ${DateFormat('dd/MM/yyyy').format(DateTime.parse(c.createdAt))}"),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
