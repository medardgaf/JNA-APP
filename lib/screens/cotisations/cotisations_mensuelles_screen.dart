import 'package:flutter/material.dart';
import '../../services/cotisation_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class CotisationsMensuellesScreen extends StatefulWidget {
  const CotisationsMensuellesScreen({super.key});

  @override
  State<CotisationsMensuellesScreen> createState() =>
      _CotisationsMensuellesScreenState();
}

class _CotisationsMensuellesScreenState
    extends State<CotisationsMensuellesScreen> {
  bool loading = true;
  List<dynamic> months = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final data = await CotisationService.getCotisations(auth.id);

    setState(() {
      months = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cotisations Mensuelles")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: months.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, i) {
                final c = months[i];
                return ListTile(
                  title: Text("${c['mois']} ${c['annee']}"),
                  subtitle: Text("Montant : ${c['montant']} FCFA"),
                  trailing: Icon(Icons.check_circle,
                      color: Colors.green.shade700, size: 28),
                );
              },
            ),
    );
  }
}
