import 'package:flutter/material.dart';
import '../../services/membre_service.dart';

class MemberPinScreen extends StatefulWidget {
  final int memberId; // On suppose que l'ID est passé
  const MemberPinScreen({super.key, required this.memberId});

  @override
  State<MemberPinScreen> createState() => _MemberPinScreenState();
}

class _MemberPinScreenState extends State<MemberPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updatePin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final res = await MembreService.updatePin(
      id: widget.memberId,
      codePin: _pinController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Opération terminée")),
      );
      if (res["success"] == true) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mettre à jour le PIN")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Entrez le nouveau code PIN à 4 chiffres."),
              const SizedBox(height: 20),
              TextFormField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: "Nouveau PIN"),
                validator: (v) => v!.length != 4 ? "4 chiffres requis" : null,
              ),
              const Spacer(),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _updatePin,
                      child: const Text("Mettre à jour"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
