import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/member_dashboard_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_pin_screen.dart';
import 'member_cotisations_screen.dart';

class MemberDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> membre;

  const MemberDashboardScreen({
    super.key,
    required this.membre,
  });

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  late Future<Map<String, dynamic>> _futureData;

  @override
  void initState() {
    super.initState();
    final id = int.tryParse(widget.membre["id"].toString()) ?? 0;
    // Assurez-vous que votre service appelle bien l'endpoint /stats.php?action=stats&membre_id=$id
    _futureData = MemberDashboardService.loadStats(id);
  }

  // -----------------------------------------------------------
  // UTILITAIRES (inchangés)
  // -----------------------------------------------------------
  num toNumber(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  String formatFCFA(dynamic v) {
    num value = toNumber(v);
    return "${value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        )} FCFA";
  }

  String formatDate(dynamic dateString) {
    if (dateString == null) return "";
    try {
      final parsedDate = DateTime.parse(dateString.toString());
      return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
    } catch (e) {
      return dateString.toString();
    }
  }

  String formatMois(dynamic moisCible) {
    if (moisCible == null) return "";
    try {
      final parts = moisCible.toString().split('-');
      if (parts.length == 2) {
        final mois = int.tryParse(parts[1]) ?? 0;
        const nomsMois = [
          '',
          'Jan',
          'Fév',
          'Mars',
          'Avr',
          'Mai',
          'Juin',
          'Juil',
          'Août',
          'Sept',
          'Oct',
          'Nov',
          'Déc'
        ];
        if (mois >= 1 && mois <= 12) {
          return '${nomsMois[mois]} ${parts[0]}';
        }
      }
      return moisCible.toString();
    } catch (e) {
      return moisCible.toString();
    }
  }

  Future<void> _payViaUSSD(num montant) async {
    // Afficher le dialog de choix du fournisseur
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.payment, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Choisir le mode de paiement",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Montant à payer : ${formatFCFA(montant)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Sélectionnez votre opérateur mobile :",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Option MIXX BY YAS
              _buildPaymentOption(
                context: context,
                title: "MIXX BY YAS",
                subtitle: "Payer via MIXX BY YAS",
                icon: Icons.phone_android,
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _launchUSSD("*155*1*$montant#", "MIXX BY YAS");
                },
              ),

              const SizedBox(height: 12),

              // Option MOOV MONEY
              _buildPaymentOption(
                context: context,
                title: "MOOV MONEY",
                subtitle: "Payer via MOOV MONEY",
                icon: Icons.phone_iphone,
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _launchUSSD("*155*2*$montant#", "MOOV MONEY");
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUSSD(String ussdCode, String provider) async {
    final uri = Uri(scheme: "tel", path: ussdCode);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);

        // Afficher un message de confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lancement du code USSD $provider..."),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Impossible de lancer le code USSD"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPinScreen()),
      (route) => false,
    );
  }

  // -----------------------------------------------------------
  // UI
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Mon espace"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                final id = int.tryParse(widget.membre["id"].toString()) ?? 0;
                _futureData = MemberDashboardService.loadStats(id);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureData,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text(
                    "Erreur de chargement",
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.danger),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${snap.error}",
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          if (!snap.hasData || snap.data == null) {
            return const Center(child: Text("Aucune donnée reçue."));
          }

          final data = snap.data!;
          if (data["success"] != true) {
            return Center(
              child: Text(
                "Erreur de chargement des données",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          // --- MODIFIÉ : Extraction directe des données de la réponse `stats` ---
          final mesCotisations = toNumber(data["mes_cotisations"]);
          final totMensuelles = toNumber(data["tot_mensuelles"]);
          final totAutres = toNumber(data["tot_autres"]);
          final totDons = toNumber(data["tot_dons"]);

          final detailsMensuelles =
              List<Map<String, dynamic>>.from(data["details_mensuelles"] ?? []);

          // DEBUG: Voir ce qui est reçu de l'API
          print("=== DEBUG COTISATIONS ===");
          print("Total mensuelles: $totMensuelles");
          print("Nombre de détails: ${detailsMensuelles.length}");
          if (detailsMensuelles.isNotEmpty) {
            print("Premier élément: ${detailsMensuelles.first}");
          }
          print("========================");

          final detailsAutres =
              List<Map<String, dynamic>>.from(data["details_autres"] ?? []);
          final detailsDons =
              List<Map<String, dynamic>>.from(data["details_dons"] ?? []);

          final arriereStats =
              Map<String, dynamic>.from(data["arriere_stats"] ?? {});
          final events = List<Map<String, dynamic>>.from(data["events"] ?? []);
          final notifications =
              List<Map<String, dynamic>>.from(data["notifications"] ?? []);
          // --- FIN DE LA MODIFICATION ---

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                final id = int.tryParse(widget.membre["id"].toString()) ?? 0;
                _futureData = MemberDashboardService.loadStats(id);
              });
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.lg),

                  // 🎉 Widget fun pour la période de cotisation
                  if (detailsMensuelles.isNotEmpty)
                    _buildCotisationPeriodWidget(detailsMensuelles),
                  if (detailsMensuelles.isNotEmpty)
                    const SizedBox(height: AppSpacing.lg),

                  // Prochain événement en haut
                  if (events.isNotEmpty) ...{
                    _buildUpcomingEvent(events.first),
                    const SizedBox(height: AppSpacing.lg),
                  },
                  if (notifications.isNotEmpty) ...{
                    _buildNotifications(notifications),
                    const SizedBox(height: AppSpacing.lg),
                  },
                  _buildSectionTitle("VOS FINANCES"),
                  const SizedBox(height: AppSpacing.md),
                  _buildSummaryCards(
                    data,
                    mesCotisations,
                    totMensuelles,
                    totAutres,
                    totDons,
                    arriereStats,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionTitle("DÉTAILS DES COTISATIONS"),
                  const SizedBox(height: AppSpacing.md),
                  // Carte cliquable pour les cotisations mensuelles
                  _buildCotisationMensuelleCard(
                    detailsMensuelles,
                    totMensuelles,
                  ),
                  _buildSection(
                    "Autres cotisations",
                    Icons.account_balance_wallet_outlined,
                    detailsAutres,
                    totAutres,
                  ),
                  _buildSection(
                    "Dons",
                    Icons.volunteer_activism,
                    detailsDons,
                    totDons,
                  ),
                  _buildArrieresSection(arriereStats),
                  const SizedBox(height: AppSpacing.lg),
                  if (events.isNotEmpty) ...{
                    _buildSectionTitle("ÉVÉNEMENTS À VENIR"),
                    const SizedBox(height: AppSpacing.md),
                    _buildEvents(events),
                    const SizedBox(height: AppSpacing.lg),
                  },
                  _buildSectionTitle("ACTIONS RAPIDES"),
                  const SizedBox(height: AppSpacing.md),
                  _buildButton(
                    label: "Payer via USSD",
                    icon: Icons.payment,
                    color: AppColors.success,
                    onPressed: () =>
                        _payViaUSSD(toNumber(arriereStats["montant_du"])),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildButton(
                    label: "Contacter l'admin",
                    icon: Icons.phone,
                    color: AppColors.primary,
                    onPressed: () async {
                      final uri = Uri(scheme: "tel", path: "+22891310096");
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -----------------------------------------------------------
  // WIDGETS (inchangés)
  // -----------------------------------------------------------
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
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
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, size: 40, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.membre["nom_complet"],
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                    (widget.membre["role"] ?? "").toString().toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUpcomingEvent(Map<String, dynamic> event) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.warning, AppColors.warning.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.3),
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
              Icons.event_available,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PROCHAIN ÉVÉNEMENT",
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  event["titre"] ?? "Événement",
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white, size: 14),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      formatDate(event["date_evenement"]),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications(List<Map<String, dynamic>> notifications) {
    return Container(
      decoration: _cardDecoration(),
      child: ExpansionTile(
        leading: Icon(Icons.notifications, color: AppColors.warning),
        title: Text(
          "Notifications (${notifications.length})",
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        children: notifications
            .map((notif) => ListTile(
                  leading: Icon(Icons.info, color: AppColors.info, size: 20),
                  title: Text(
                    notif["titre"] ?? "Notification",
                    style: AppTextStyles.bodyMedium,
                  ),
                  subtitle: Text(
                    notif["message"] ?? "",
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: Text(
                    formatDate(notif["date_envoi"] ?? ""),
                    style: AppTextStyles.caption,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSummaryCards(
    Map<String, dynamic> data,
    num mesCotisations,
    num totMensuelles,
    num totAutres,
    num totDons,
    Map arriereStats,
  ) {
    // Calculer les stats de présence
    final presenceStats = data["presence_stats"] ?? {};
    final totalReunions = presenceStats["total_reunions"] ?? 0;
    final presences = presenceStats["presences"] ?? 0;
    final tauxPresence =
        totalReunions > 0 ? ((presences / totalReunions) * 100).toInt() : 0;

    return Column(
      children: [
        Row(children: [
          Expanded(
            child: _summaryCard(
              "Présence réunions",
              Icons.how_to_reg,
              AppColors.info,
              "$tauxPresence%",
              subtitle: "$presences/$totalReunions",
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _summaryCard("Mensuelles", Icons.savings,
                  AppColors.primary, formatFCFA(totMensuelles))),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Expanded(
              child: _summaryCard("Autres", Icons.wallet_outlined,
                  AppColors.info, formatFCFA(totAutres))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _summaryCard("Dons", Icons.volunteer_activism,
                  AppColors.purple, formatFCFA(totDons))),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Expanded(
              child: _summaryCard("Arriérés", Icons.warning, AppColors.warning,
                  "${arriereStats["total_arrieres"] ?? 0} mois")),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _summaryCard("Montant dû", Icons.money_off,
                  AppColors.danger, formatFCFA(arriereStats["montant_du"]))),
        ]),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    IconData icon,
    Color color,
    String value, {
    String? subtitle,
  }) {
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
          if (subtitle != null) ...{
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: color.withOpacity(0.7),
              ),
            ),
          },
        ],
      ),
    );
  }

  Widget _buildCotisationMensuelleCard(
    List<Map<String, dynamic>> detailsMensuelles,
    dynamic total,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MemberCotisationsScreen(
              cotisations: detailsMensuelles,
              membreId: int.tryParse(widget.membre["id"].toString()) ?? 0,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
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
        child: Row(
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.calendar_month,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Cotisations mensuelles",
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    "${detailsMensuelles.length} cotisation${detailsMensuelles.length > 1 ? 's' : ''}",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    "Total: ${formatFCFA(total)}",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Flèche
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon,
      List<Map<String, dynamic>> list, dynamic total,
      {bool isMensuelle = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.blue, size: 22),
        title: Row(
          children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text("${list.length} opération(s)",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text("Total: ${formatFCFA(total)}",
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
        children: list.isEmpty
            ? [const ListTile(title: Text("Aucun enregistrement"))]
            : list
                .map((e) => _detailTile(e, isMensuelle: isMensuelle))
                .toList(),
      ),
    );
  }

  Widget _detailTile(Map<String, dynamic> e, {bool isMensuelle = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.green.shade100, shape: BoxShape.circle),
            child:
                const Icon(Icons.check_circle, color: Colors.green, size: 18)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${formatFCFA(e["montant"])}",
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (e["description"] != null &&
                e["description"].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(e["description"].toString(),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            if (isMensuelle && e["mois_cible"] != null)
              Padding(
                padding: const EdgeInsets.only(top: 1.0),
                child: Text("Mois: ${formatMois(e["mois_cible"])}",
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Date: ${formatDate(e["date_operation"])}",
                  style: const TextStyle(fontSize: 10)),
              if (e["membre_id"] != null)
                Text("Membre ID: ${e["membre_id"]}",
                    style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }

  Widget _buildArrieresSection(Map arriereStats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
      child: ExpansionTile(
        leading: const Icon(Icons.warning, color: Colors.orange, size: 22),
        title:
            const Text("Détails des arriérés", style: TextStyle(fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text("Total: ${formatFCFA(arriereStats["montant_du"])}",
              style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
        ),
        children: [
          ListTile(
              dense: true,
              leading: const Icon(Icons.calendar_today,
                  color: Colors.blue, size: 20),
              title: Text(
                  "Mois d'arriérés: ${arriereStats["total_arrieres"] ?? 0}",
                  style: const TextStyle(fontSize: 13))),
          ListTile(
              dense: true,
              leading: const Icon(Icons.money_off, color: Colors.red, size: 20),
              title: Text(
                  "Montant dû: ${formatFCFA(arriereStats["montant_du"])}",
                  style: const TextStyle(fontSize: 13))),
          ListTile(
              dense: true,
              leading:
                  const Icon(Icons.payments, color: Colors.green, size: 20),
              title: Text(
                  "Montant payé: ${formatFCFA(arriereStats["montant_paye"])}",
                  style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildEvents(List events) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
      child: ExpansionTile(
        leading: const Icon(Icons.event, color: Colors.orange, size: 22),
        title: Text("Événements (${events.length})",
            style: const TextStyle(fontSize: 14)),
        children: events.isEmpty
            ? [const ListTile(title: Text("Aucun événement"))]
            : events
                .map((e) => Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        leading: const Icon(Icons.event_available,
                            color: Colors.orange, size: 20),
                        title: Text(e["titre"] ?? "Événement",
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                            "Date: ${formatDate(e["date_evenement"])}",
                            style: const TextStyle(fontSize: 11)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      ),
                    ))
                .toList(),
      ),
    );
  }

  Widget _buildButton(
      {required VoidCallback onPressed,
      required String label,
      required IconData icon,
      required Color color}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildCotisationPeriodWidget(List<Map<String, dynamic>> cotisations) {
    if (cotisations.isEmpty) return const SizedBox.shrink();

    final firstMois = cotisations.first['mois_cible']?.toString() ?? '';
    final lastMois = cotisations.last['mois_cible']?.toString() ?? '';
    final firstFormatted = formatMois(firstMois);
    final lastFormatted = formatMois(lastMois);

    return Container(
      padding: const EdgeInsets.all(10), // Reduced padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('🎉',
                style: TextStyle(fontSize: 16)), // Reduced emoji size
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cotisations à jour !',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13, // Reduced font size
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cotisations.length} mois payés',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11), // Reduced font size
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 6), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(firstFormatted,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11, // Reduced font size
                        fontWeight: FontWeight.bold)),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 4), // Reduced padding
                  child: Icon(Icons.arrow_forward,
                      color: Colors.white, size: 12), // Reduced icon size
                ),
                Text(lastFormatted,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11, // Reduced font size
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2))
      ],
    );
  }
}
