import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Assure-toi que les imports correspondent à ton architecture de dossiers
import 'package:kliv_app/screens/operations/add_unified_operation_screen.dart';
import 'package:kliv_app/screens/arrieres/arrieres_screen.dart';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../services/operations_services.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  List<Map<String, dynamic>> _operations = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  int _selectedView = 0; // 0: Liste, 1: Groupé par membre

  // ID de la catégorie Dons (doit correspondre à ta base de données)
  static const int CATEGORIE_DONS_ID = 3;

  @override
  void initState() {
    super.initState();
    _loadOperations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOperations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Appel au backend: index.php?action=all
      // Note: On n'exclut pas les dons ici pour pouvoir les calculer côté client
      final result = await OperationService.getAll();
      if (mounted) {
        setState(() {
          _operations = List<Map<String, dynamic>>.from(result["data"] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteOperation(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette opération ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await OperationService.delete(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result["message"] ?? "Opération supprimée"),
              backgroundColor:
                  result["success"] == true ? Colors.green : Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (result["success"] == true) {
            _loadOperations();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur: $e"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _navigateToAdd() {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (context) => const AddUnifiedOperationScreen()))
        .then((_) => _loadOperations());
  }

  void _navigateToEdit(Map<String, dynamic> operation) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (context) =>
                AddUnifiedOperationScreen(operation: operation)))
        .then((_) => _loadOperations());
  }

  void _navigateToArrieres() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ArrieresScreen()),
    );
  }

  // === LOGIQUE DE TRI ET CALCUL (Basée sur le backend) ===

  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  // Filtre: Type = 'recette' ET Categorie = 3
  List<Map<String, dynamic>> get _dons {
    return _operations.where((op) {
      final categorieId = _safeParseInt(op['categorie_id']);
      return categorieId == CATEGORIE_DONS_ID &&
          (op['type'] == 'recette' || op['type'] == 'entree');
    }).toList();
  }

  // Filtre: Type = 'recette' ET Categorie != 3
  List<Map<String, dynamic>> get _autresRecettes {
    return _operations.where((op) {
      final categorieId = _safeParseInt(op['categorie_id']);
      return (op['type'] == 'recette' || op['type'] == 'entree') &&
          categorieId != CATEGORIE_DONS_ID;
    }).toList();
  }

  // Filtre: Type = 'depense'
  List<Map<String, dynamic>> get _depenses {
    return _operations
        .where((op) => op['type'] == 'depense' || op['type'] == 'sortie')
        .toList();
  }

  double _calculateTotal(List<Map<String, dynamic>> ops) {
    return ops.fold(0.0, (sum, op) {
      final montant = double.tryParse(op['montant'].toString()) ?? 0.0;
      return sum + montant;
    });
  }

  double get _totalDons => _calculateTotal(_dons);
  double get _totalAutresRecettes => _calculateTotal(_autresRecettes);
  double get _totalDepenses => _calculateTotal(_depenses);
  double get _soldeReel => _totalAutresRecettes - _totalDepenses;

  List<Map<String, dynamic>> get _filteredOperations {
    if (_searchQuery.isEmpty) return _operations;
    return _operations.where((op) {
      final nomMembre = "${op['membre_nom'] ?? ''} ${op['membre_prenom'] ?? ''}"
          .toLowerCase();
      final categorie = op['categorie_nom']?.toString().toLowerCase() ?? '';
      final description = op['description']?.toString().toLowerCase() ?? '';
      final montant = op['montant'].toString();

      // Gestion de la date sécurisée
      String dateStr = '';
      if (op['date_operation'] != null) {
        try {
          dateStr = DateFormat('dd MMM yyyy')
              .format(DateTime.parse(op['date_operation']));
        } catch (e) {
          dateStr = '';
        }
      }

      return nomMembre.contains(_searchQuery.toLowerCase()) ||
          categorie.contains(_searchQuery.toLowerCase()) ||
          description.contains(_searchQuery.toLowerCase()) ||
          montant.contains(_searchQuery) ||
          dateStr.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _operationsByMember {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final operation in _filteredOperations) {
      final membreId = operation['membre_id']?.toString() ?? '0';
      // Si pas de membre (ex: dépense générale), on regroupe sous "Général"
      final membreNom = (operation['membre_nom'] != null)
          ? "${operation['membre_nom']} ${operation['membre_prenom']}"
          : "Opérations Générales";

      final key = '$membreId|$membreNom';

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(operation);
    }
    return grouped;
  }

  Future<void> exportToExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Opérations'];

      sheet.appendRow([
        'ID',
        'Date',
        'Type',
        'Catégorie',
        'Montant',
        'Membre',
        'Description'
      ]);

      for (final op in _filteredOperations) {
        // Formatage date
        String dateStr = op['date_operation']?.toString() ?? '';
        try {
          if (dateStr.isNotEmpty) {
            dateStr = DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
          }
        } catch (_) {}

        final membreNom = (op['membre_nom'] != null)
            ? "${op['membre_nom']} ${op['membre_prenom']}"
            : "Général";

        sheet.appendRow([
          op['id'],
          dateStr,
          op['type'],
          op['categorie_nom'],
          op['montant'],
          membreNom,
          op['description']
        ]);
      }

      // Vérification de la version Android (Uniquement si ce n'est pas le Web)
      bool storagePermissionNeeded = true;
      if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          storagePermissionNeeded =
              false; // Pas besoin de WRITE_EXTERNAL_STORAGE sur Android 13+
        }
      } else if (kIsWeb) {
        storagePermissionNeeded =
            false; // Pas de permission de stockage sur le Web
      } else {
        storagePermissionNeeded = false; // iOS/Desktop
      }

      if (!kIsWeb && storagePermissionNeeded) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permission de stockage refusée")),
          );
          return;
        }
      }

      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "L'export sur Web n'est pas encore supporté dans cette version.")),
        );
        return;
      }

      Directory? dir;
      if (Platform.isAndroid) {
        if (!storagePermissionNeeded) {
          dir = await getExternalStorageDirectory();
        } else {
          dir = Directory('/storage/emulated/0/Download');
          if (!await dir.exists()) {
            dir = await getExternalStorageDirectory();
          }
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Impossible d'accéder au dossier de stockage")),
        );
        return;
      }

      final filePath =
          "${dir.path}/operations_export_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final fileBytes = excel.encode();
      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Export réussi : $filePath"),
            duration: const Duration(seconds: 5)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur export : ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des opérations'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.view_list),
            onSelected: (value) => setState(() => _selectedView = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0, child: Text('Vue liste')),
              const PopupMenuItem(value: 1, child: Text('Groupé par membre')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Arriérés',
            onPressed: _navigateToArrieres,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOperations,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter',
            onPressed: exportToExcel,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    if (_isLoading || _operations.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.arrow_downward,
                  '${_totalAutresRecettes.toInt()}', 'Recettes', Colors.green),
              _buildStatItem(Icons.arrow_upward, '${_totalDepenses.toInt()}',
                  'Dépenses', Colors.red),
              _buildStatItem(Icons.account_balance, '${_soldeReel.toInt()}',
                  'Solde', _soldeReel >= 0 ? Colors.blue : Colors.red),
            ],
          ),
          if (_totalDons > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volunteer_activism,
                      color: Colors.purple, size: 16),
                  const SizedBox(width: 8),
                  Text('Dons : ${_totalDons.toInt()} FCFA (Indicatif)',
                      style: TextStyle(
                          color: Colors.purple.shade800,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
          child: Text('Erreur: $_error',
              style: const TextStyle(color: Colors.red)));
    if (_operations.isEmpty)
      return const Center(child: Text("Aucune opération trouvée"));

    return RefreshIndicator(
      onRefresh: _loadOperations,
      child: _selectedView == 0 ? _buildListView() : _buildGroupedView(),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Espace pour le FAB
      itemCount: _filteredOperations.length,
      itemBuilder: (context, index) =>
          _buildOperationTile(_filteredOperations[index]),
    );
  }

  Widget _buildGroupedView() {
    final grouped = _operationsByMember;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final key = grouped.keys.elementAt(index);
        final operations = grouped[key]!;
        final parts = key.split('|');
        final membreNom = parts[1];
        final total = _calculateTotal(operations);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(membreNom.substring(0, 1).toUpperCase()),
            ),
            title: Text(membreNom,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${operations.length} opérations'),
            trailing: Text('${total.toInt()} F',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            children: operations.map((op) => _buildOperationTile(op)).toList(),
          ),
        );
      },
    );
  }

  // === PARTIE QUI ÉTAIT COUPÉE DANS TA VERSION ===
  Widget _buildOperationTile(Map<String, dynamic> operation) {
    // Récupération des données sécurisée
    final id = _safeParseInt(operation['id']);
    final type = operation['type']; // 'recette' ou 'depense'
    final isRecette = type == 'recette' || type == 'entree';

    final montant = double.tryParse(operation['montant'].toString()) ?? 0.0;
    final categorieNom = operation['categorie_nom'] ?? 'Non classé';
    final description = operation['description'] ?? '';

    // Formatage de la date
    String dateFormatted = 'Date inconnue';
    if (operation['date_operation'] != null) {
      try {
        final date = DateTime.parse(operation['date_operation']);
        dateFormatted = DateFormat('dd MMM yyyy', 'fr_FR').format(date);
      } catch (e) {
        // Fallback si le format date échoue
        dateFormatted = operation['date_operation'].toString();
      }
    }

    // Détermination de la couleur et de l'icône
    final color = isRecette ? Colors.green : Colors.red;
    final icon = isRecette ? Icons.arrow_downward : Icons.arrow_upward;
    final sign = isRecette ? '+' : '-';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0.5,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                categorieNom,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$sign${montant.toInt()} FCFA',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              dateFormatted,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _navigateToEdit(operation);
            } else if (value == 'delete' && id != null) {
              _deleteOperation(id);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Modifier'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Supprimer'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucune opération enregistrée',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOperations,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            )
          ],
        ),
      ),
    );
  }
}
