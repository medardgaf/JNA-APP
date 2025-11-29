import 'package:flutter/material.dart';
import '../../services/cotisation_service.dart';
import '../../services/membre_service.dart';
import '../../widgets/search_bar.dart';

class CotisationsTresorierScreen extends StatefulWidget {
  const CotisationsTresorierScreen({super.key});

  @override
  State<CotisationsTresorierScreen> createState() =>
      _CotisationsTresorierScreenState();
}

class _CotisationsTresorierScreenState
    extends State<CotisationsTresorierScreen> {
  bool loading = true;
  List<dynamic> membres = [];
  List<dynamic> filtered = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final list = await MembreService.getAll();

    setState(() {
      membres = list;
      filtered = list;
      loading = false;
    });
  }

  void search(String t) {
    setState(() {
      filtered = membres
          .where((m) => m["nom_complet"]
              .toString()
              .toLowerCase()
              .contains(t.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestion Cotisations")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SearchBarWidget(onChanged: search),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final m = filtered[i];
                      return ListTile(
                        title: Text(m["nom_complet"]),
                        subtitle: Text("Rôle : ${m['role']}"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            "/cotisations/membre",
                            arguments: m,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
