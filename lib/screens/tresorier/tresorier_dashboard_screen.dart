import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/tresorier_service.dart';
import '../../theme/app_theme.dart';

class TresorierDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const TresorierDashboardScreen({super.key, required this.user});

  @override
  State<TresorierDashboardScreen> createState() =>
      _TresorierDashboardScreenState();
}

class _TresorierDashboardScreenState extends State<TresorierDashboardScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _operations = [];
  Map<String, dynamic> _stats = {};
  int? _categorieId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await TresorierService.getDashboardData();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'] ?? {};
        setState(() {
          _operations =
              List<Map<String, dynamic>>.from(data['operations'] ?? []);
          _stats = data['stats'] ?? {};
          _categorieId = data['categorie_id'];
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Erreur inconnue';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur: $e';
        _loading = false;
      });
    }
  }

  String _formatFCFA(dynamic value) {
    final num montant =
        value is num ? value : num.tryParse(value?.toString() ?? '0') ?? 0;
    return "${montant.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        )} FCFA";
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    try {
      final parsedDate = DateTime.parse(dateString.toString());
      return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
    } catch (e) {
      return dateString.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activités Génératrices'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportExcel,
            tooltip: 'Exporter Excel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildStatsCards(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildSectionTitle('OPÉRATIONS'),
                        const SizedBox(height: AppSpacing.md),
                        _buildOperationsList(),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user['nom_complet'] ?? 'Trésorier',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'TRÉSORIER',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalEntrees = _stats['total_entrees'] ?? 0;
    final totalSorties = _stats['total_sorties'] ?? 0;
    final benefice = _stats['benefice'] ?? 0;
    final nombreOps = _stats['nombre_operations'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Revenus',
                Icons.trending_up,
                AppColors.success,
                _formatFCFA(totalEntrees),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                'Dépenses',
                Icons.trending_down,
                AppColors.danger,
                _formatFCFA(totalSorties),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Bénéfice',
                Icons.account_balance,
                benefice >= 0 ? AppColors.primary : AppColors.warning,
                _formatFCFA(benefice),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                'Opérations',
                Icons.receipt_long,
                AppColors.info,
                nombreOps.toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, IconData icon, Color color, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildOperationsList() {
    if (_operations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Aucune opération',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Appuyez sur + pour ajouter une opération',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _operations.map((op) => _buildOperationCard(op)).toList(),
    );
  }

  Widget _buildOperationCard(Map<String, dynamic> operation) {
    final type = operation['type'] ?? '';
    final montant = operation['montant'];
    final date = operation['date_operation'];
    final description = operation['description']?.toString() ?? '';
    final isEntree = type == 'recette' || type == 'entree';
    final id = operation['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: (isEntree ? AppColors.success : AppColors.danger)
              .withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: (isEntree ? AppColors.success : AppColors.danger)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            isEntree ? Icons.arrow_downward : Icons.arrow_upward,
            color: isEntree ? AppColors.success : AppColors.danger,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEntree ? 'Revenu' : 'Dépense',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isEntree ? AppColors.success : AppColors.danger,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              _formatFCFA(montant),
              style: AppTextStyles.heading3.copyWith(
                color: isEntree ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            _formatDate(date),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditDialog(operation);
            } else if (value == 'delete') {
              _confirmDelete(
                  id,
                  description.isNotEmpty
                      ? description
                      : (isEntree ? 'Revenu' : 'Dépense'));
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Modifier'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.danger, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Supprimer', style: TextStyle(color: AppColors.danger)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Erreur de chargement',
              style: AppTextStyles.heading3.copyWith(color: AppColors.danger),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => _OperationDialog(
        onSave: (type, montant, date, description) async {
          final result = await TresorierService.addOperation(
            type: type,
            montant: montant,
            dateOperation: date,
            description: description,
          );

          if (!mounted) return;

          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Opération ajoutée'),
                backgroundColor: AppColors.success,
              ),
            );
            _loadData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Erreur'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> operation) {
    showDialog(
      context: context,
      builder: (context) => _OperationDialog(
        operation: operation,
        onSave: (type, montant, date, description) async {
          final result = await TresorierService.updateOperation(
            id: operation['id'],
            type: type,
            montant: montant,
            dateOperation: date,
            description: description,
          );

          if (!mounted) return;

          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Opération modifiée'),
                backgroundColor: AppColors.success,
              ),
            );
            _loadData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Erreur'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(int id, String label) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "$label" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final result = await TresorierService.deleteOperation(id);

              if (!mounted) return;

              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Opération supprimée'),
                    backgroundColor: AppColors.success,
                  ),
                );
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Erreur'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: Text('Supprimer', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportExcel() async {
    try {
      final url = Uri.parse(TresorierService.getExportUrl());
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le fichier')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}

// Dialog pour ajouter/modifier une opération
class _OperationDialog extends StatefulWidget {
  final Map<String, dynamic>? operation;
  final Function(String type, double montant, String date, String? description)
      onSave;

  const _OperationDialog({
    this.operation,
    required this.onSave,
  });

  @override
  State<_OperationDialog> createState() => _OperationDialogState();
}

class _OperationDialogState extends State<_OperationDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  final _montantController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.operation != null) {
      final op = widget.operation!;
      _type = op['type'] ?? 'recette';
      _montantController.text = op['montant']?.toString() ?? '';
      _dateController.text = op['date_operation'] ?? '';
      _descriptionController.text = op['description'] ?? '';
    } else {
      _type = 'recette';
      _dateController.text = DateTime.now().toString().split(' ')[0];
    }
  }

  @override
  void dispose() {
    _montantController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.operation != null;

    return AlertDialog(
      title: Text(isEdit ? 'Modifier l\'opération' : 'Nouvelle opération'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'recette', child: Text('Revenu')),
                  DropdownMenuItem(value: 'depense', child: Text('Dépense')),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montantController,
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Montant requis';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    _dateController.text = date.toString().split(' ')[0];
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Date requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _type,
                double.parse(_montantController.text),
                _dateController.text,
                _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(isEdit ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }
}
