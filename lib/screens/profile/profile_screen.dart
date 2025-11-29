import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'change_pin_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Profil"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: ListTile(
              title: Text("${user["nom_complet"] ?? "Utilisateur"}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text("Rôle : ${auth.role}"),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Changer mon code PIN"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChangePinScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title:
                const Text("Déconnexion", style: TextStyle(color: Colors.red)),
            onTap: () {
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, "/login", (_) => false);
            },
          )
        ],
      ),
    );
  }
}
