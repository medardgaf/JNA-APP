import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/cotisation_service.dart';
import 'payer_cotisation_screen.dart';

class CotisationsScreen extends StatefulWidget {
  const CotisationsScreen({super.key});

  @override
  State<CotisationsScreen> createState() => _CotisationsScreenState();
}

class _CotisationsScreenState extends State<CotisationsScreen> {
  bool loading = true;
  String? error;

  Map<String, dynamic> data = {};

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
      final res = await CotisationService.getCotisations(auth.id);

      if (mounted) {
        setState(() {
          data = res;
        });
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(child: Text("Erreur : $error")),
      );
    }

    final payes = data["mois_paye"] ?? [];
    final impayes = data["mois_impayes"] ?? [];
    final impayesCalcules = data["mois_impayes_calcules"] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Cotisations"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Mois payés",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...payes.map((e) => _item("Payé", e)).toList(),
          const SizedBox(height: 20),
          Text(
            "Arriérés",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...impayes.map((e) => _item("Arriéré", e)).toList(),
          const SizedBox(height: 20),
          Text(
            "Impayés calculés",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...impayesCalcules.map((e) => _item("Impayé", e)).toList(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PayerCotisationScreen(membreId: auth.id),
                ),
              );
            },
            child: const Text("Payer une cotisation"),
          ),
        ],
      ),
    );
  }

  Widget _item(String label, Map e) {
    final mois = e["mois"];
    final annee = e["annee"];
    final montant = e["montant"] ?? e["montant_du"];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label : $mois/$annee"),
          Text("${montant.toString()} FCFA"),
        ],
      ),
    );
  }
}
