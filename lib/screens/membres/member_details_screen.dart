import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/membre_service.dart';

class MemberDetailsScreen extends StatefulWidget {
  final int id;
  final Map<String, dynamic>? membre;

  const MemberDetailsScreen({
    super.key,
    required this.id,
    this.membre,
  });

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  bool _loading = true;
  bool _pinLoading = false; // État de chargement spécifique au PIN
  Map<String, dynamic>? _membreData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  Future<void> _loadMember() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final data = await MembreService.getOne(widget.id);
    if (mounted) {
      setState(() {
        _loading = false;
        if (data != null) {
          _membreData = data;
        } else {
          _error = "Membre introuvable";
        }
      });
    }
  }

  /// Récupère et affiche le PIN dans une boîte de dialogue
  Future<void> _revealPin() async {
    setState(() => _pinLoading = true);

    final pin = await MembreService.getMemberPin(widget.id);

    if (mounted) {
      setState(() => _pinLoading = false);

      if (pin != null) {
        _showPinDialog(pin);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible de récupérer le code PIN."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPinDialog(String pin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Code PIN"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Voici le code PIN du membre :"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                pin,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_membreData?["nom_complet"] ?? "Détails du membre"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMember,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMember,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_membreData == null) {
      return const Center(child: Text("Aucune donnée disponible"));
    }

    return RefreshIndicator(
      onRefresh: _loadMember,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildSectionTitle("Informations personnelles"),
            _buildDetailTile("Code PIN", "••••", isPin: true),
            _buildDetailTile("Téléphone", _membreData!["telephone"]),
            const SizedBox(height: 16),
            _buildSectionTitle("Informations d'adhésion"),
            _buildDetailTile("Date d'adhésion", _membreData!["date_adhesion"],
                isDate: true),
            const SizedBox(height: 16),
            _buildSectionTitle("Arriérés & Solde"),
            _buildDetailTile(
                "Prochain mois à payer", _membreData!["date_debut_arriere"],
                isDate: true),
            _buildDetailTile("Statut arriéré", _membreData!["statut_arriere"]),
            _buildDetailTile("Montant arriéré", _membreData!["montant_arriere"],
                isCurrency: true),
            _buildDetailTile("Solde crédit", _membreData!["solde_credit"],
                isCurrency: true),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                "${_membreData!["nom"][0]}${_membreData!["prenom"][0]}"
                    .toUpperCase(),
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_membreData!["nom_complet"],
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Chip(
                          label: Text(_membreData!["role"] ?? "N/A"),
                          backgroundColor: Colors.blue.shade100),
                      const SizedBox(width: 8),
                      Chip(
                          label: Text(_membreData!["statut"] ?? "N/A"),
                          backgroundColor: Colors.green.shade100),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87)),
    );
  }

  Widget _buildDetailTile(String title, dynamic value,
      {bool isDate = false, bool isCurrency = false, bool isPin = false}) {
    String displayValue = 'Non défini';
    if (value != null && value != 'NULL') {
      if (isDate) {
        try {
          displayValue =
              DateFormat('dd MMMM yyyy').format(DateTime.parse(value));
        } catch (e) {
          displayValue = value.toString();
        }
      } else if (isCurrency) {
        displayValue =
            "${double.parse(value.toString()).toStringAsFixed(2)} FCFA";
      } else {
        displayValue = value.toString();
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(_getIconForField(title), color: Colors.blue.shade700),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(displayValue),
        trailing: isPin
            ? _pinLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: _revealPin,
                    tooltip: "Voir le code PIN",
                  )
            : null,
      ),
    );
  }

  IconData _getIconForField(String title) {
    switch (title) {
      case "Code PIN":
        return Icons.password;
      case "Téléphone":
        return Icons.phone;
      case "Date d'adhésion":
      case "Prochain mois à payer":
        return Icons.calendar_today;
      case "Montant arriéré":
      case "Solde crédit":
        return Icons.account_balance_wallet;
      default:
        return Icons.info_outline;
    }
  }
}
