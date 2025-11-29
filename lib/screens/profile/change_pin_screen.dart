import 'package:flutter/material.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  String? oldPin;
  String? newPin;
  String? confirmPin;
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Changer PIN"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            obscureText: true,
            decoration: const InputDecoration(
                labelText: "Ancien PIN", border: OutlineInputBorder()),
            onChanged: (v) => oldPin = v,
          ),
          const SizedBox(height: 16),
          TextField(
            obscureText: true,
            decoration: const InputDecoration(
                labelText: "Nouveau PIN", border: OutlineInputBorder()),
            onChanged: (v) => newPin = v,
          ),
          const SizedBox(height: 16),
          TextField(
            obscureText: true,
            decoration: const InputDecoration(
                labelText: "Confirmer PIN", border: OutlineInputBorder()),
            onChanged: (v) => confirmPin = v,
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50)),
            onPressed: sending
                ? null
                : () {
                    if (newPin != confirmPin) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("PIN non identiques")));
                      return;
                    }

                    // TODO — envoyer au backend
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("PIN mis à jour")));

                    Navigator.pop(context);
                  },
            child: sending
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Mettre à jour"),
          )
        ],
      ),
    );
  }
}
