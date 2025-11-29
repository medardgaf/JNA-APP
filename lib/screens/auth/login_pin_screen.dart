import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import 'member_dashboard_screen.dart';
import '../dashboard/dashboard_screen.dart'; // ✅ import du dashboard générique
import '../tresorier/tresorier_dashboard_screen.dart';

class LoginPinScreen extends StatefulWidget {
  const LoginPinScreen({super.key});

  @override
  State<LoginPinScreen> createState() => _LoginPinScreenState();
}

class _LoginPinScreenState extends State<LoginPinScreen> {
  final pinCtrl = TextEditingController();
  bool loading = false;
  String? errorMessage;

  Future<void> handleLogin() async {
    if (pinCtrl.text.length != 4) {
      setState(() {
        errorMessage = "Le code PIN doit contenir 4 chiffres.";
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final data = await AuthService.loginWithPin(pinCtrl.text.trim());

      if (data["success"] == true) {
        final user = data["membre"];
        Provider.of<AuthProvider>(context, listen: false).setAuth(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Bienvenue ${user['nom_complet']} 👋"),
              backgroundColor: Colors.green,
            ),
          );

          // ✅ Redirection selon le rôle
          final role = (user["role"] ?? "").toLowerCase();

          if (role == "membre") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MemberDashboardScreen(membre: user),
              ),
            );
          } else if (role == "tresorier") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TresorierDashboardScreen(user: user),
              ),
            );
          } else {
            // Admin, Secrétaire, etc.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DashboardScreen(),
              ),
            );
          }
        }
      } else {
        setState(() {
          errorMessage = data["message"] ?? "Code PIN incorrect.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Une erreur est survenue. Réessayez.";
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Center(
                child: Column(
                  children: [
                    Image(
                      image: AssetImage('assets/images/logo.png'),
                      width: 120,
                      height: 120,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "JNA ADMINISTRATION",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Votre espace associatif sécurisé",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "Connexion",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  labelText: "Code PIN à 4 chiffres",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.blue),
                        )
                      : ElevatedButton(
                          key: const ValueKey("loginBtn"),
                          onPressed: handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Se connecter",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add, color: Colors.blue),
                  label: const Text(
                    "Créer un compte",
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
