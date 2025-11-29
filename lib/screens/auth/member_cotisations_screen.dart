import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MemberCotisationsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cotisations;
  final int membreId;

  const MemberCotisationsScreen({
    super.key,
    required this.cotisations,
    required this.membreId,
  });

  @override
  State<MemberCotisationsScreen> createState() =>
      _MemberCotisationsScreenState();
}

class _MemberCotisationsScreenState extends State<MemberCotisationsScreen> {
  String? _selectedYear;
  String? _selectedMonth;

  List<String> _availableYears = [];
  List<String> _availableMonths = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre'
  ];

  @override
  void initState() {
    super.initState();
    _extractYears();
  }

  void _extractYears() {
    final years = <String>{};
    for (var cot in widget.cotisations) {
      final moisCible = cot['mois_cible']?.toString() ?? '';
      if (moisCible.isNotEmpty) {
        final parts = moisCible.split('-');
        if (parts.isNotEmpty) {
          years.add(parts[0]);
        }
      }
    }
    _availableYears = years.toList()..sort((a, b) => b.compareTo(a));
  }

  List<Map<String, dynamic>> get _filteredCotisations {
    var filtered = widget.cotisations.toList();

    // Filtre par année
    if (_selectedYear != null) {
      filtered = filtered.where((cot) {
        final moisCible = cot['mois_cible']?.toString() ?? '';
        return moisCible.startsWith(_selectedYear!);
      }).toList();
    }

    // Filtre par mois
    if (_selectedMonth != null) {
      final monthIndex = _availableMonths.indexOf(_selectedMonth!) + 1;
      final monthStr = monthIndex.toString().padLeft(2, '0');
      filtered = filtered.where((cot) {
        final moisCible = cot['mois_cible']?.toString() ?? '';
        final parts = moisCible.split('-');
        return parts.length > 1 && parts[1] == monthStr;
      }).toList();
    }

    return filtered;
  }

  String _formatMois(String? moisCible) {
    if (moisCible == null || moisCible.isEmpty) return '';
    try {
      final parts = moisCible.split('-');
      if (parts.length == 2) {
        final mois = int.tryParse(parts[1]) ?? 0;
        if (mois >= 1 && mois <= 12) {
          return '${_availableMonths[mois - 1]} ${parts[0]}';
        }
      }
      return moisCible;
    } catch (e) {
      return moisCible;
    }
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

  String _formatFCFA(dynamic value) {
    final num montant =
        value is num ? value : num.tryParse(value?.toString() ?? '0') ?? 0;
    return "${montant.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        )} FCFA";
  }

  num _calculateTotal() {
    return _filteredCotisations.fold<num>(0, (sum, cot) {
      final montant = cot['montant'];
      final num value = montant is num
          ? montant
          : num.tryParse(montant?.toString() ?? '0') ?? 0;
      return sum + value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();
    final filteredCount = _filteredCotisations.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Cotisations Mensuelles'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // En-tête avec statistiques
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatFCFA(total),
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$filteredCount cotisation${filteredCount > 1 ? 's' : ''}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Filtres
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FILTRES',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    // Filtre par année
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedYear,
                        decoration: InputDecoration(
                          labelText: 'Année',
                          prefixIcon: Icon(Icons.calendar_today,
                              color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Toutes')),
                          ..._availableYears.map((year) => DropdownMenuItem(
                                value: year,
                                child: Text(year),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedYear = value);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Filtre par mois
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedMonth,
                        decoration: InputDecoration(
                          labelText: 'Mois',
                          prefixIcon:
                              Icon(Icons.event, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Tous')),
                          ..._availableMonths.map((month) => DropdownMenuItem(
                                value: month,
                                child: Text(month),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedMonth = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des cotisations
          Expanded(
            child: _filteredCotisations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Aucune cotisation trouvée',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Essayez de modifier les filtres',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _filteredCotisations.length,
                    itemBuilder: (context, index) {
                      final cot = _filteredCotisations[index];
                      return _buildCotisationCard(cot);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCotisationCard(Map<String, dynamic> cot) {
    final montant = cot['montant'];
    final moisCible = cot['mois_cible'];
    final dateOperation = cot['date_operation'];
    final description = cot['description']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec mois et montant
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          Icons.calendar_month,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _formatMois(moisCible),
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatFCFA(montant),
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: AppSpacing.sm),

            // Date de paiement
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Payé le ${_formatDate(dateOperation)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
