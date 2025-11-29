import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/dashboard_service.dart';

// Imports de tes écrans (Gardés tels quels)
import '../operations/operations_screen.dart';
import '../cotisations/cotisations_screen.dart';
import '../membres/members_list_screen.dart';
import '../categories/category_screen.dart';
import '../profile/profile_screen.dart';
import '../reunions/reunions_screen.dart';
import '../reunions/reunion_add_screen.dart';
import '../reunions/reunion_presence_screen.dart';
import '../evenements/events_screen.dart';
import '../evenements/event_add_screen.dart';
import '../evenements/event_calendar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<Map<String, dynamic>>? _statsFuture;
  bool _isInit = false;

  // Couleurs
  static const Color _primaryColor = Color(0xFF4A90E2);
  static const Color _successColor = Color(0xFF5CB85C);
  static const Color _warningColor = Color(0xFFF0AD4E);
  static const Color _dangerColor = Color(0xFFD9534F);
  static const Color _purpleColor = Color(0xFF9B59B6);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On initialise le chargement UNE SEULE FOIS quand le contexte est prêt
    if (!_isInit) {
      _loadStats();
      _isInit = true;
    }
  }

  void _loadStats() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    if (user != null) {
      final role = user["role"] ?? "membre";
      // Conversion sécurisée de l'ID en int
      final memberId = int.tryParse(user["id"].toString()) ?? 0;

      setState(() {
        _statsFuture = DashboardService.loadStats(role, memberId);
      });
    }
  }

  Future<void> _refreshStats() async {
    _loadStats();
    await _statsFuture; // Attendre la fin pour le RefreshIndicator
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return "0 FCFA";
    final value = double.tryParse(amount.toString()) ?? 0.0;
    return "${value.toInt().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA";
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
          body: Center(child: Text("Utilisateur non connecté")));
    }

    final role = user["role"] ?? "inconnu";
    final fullname = user["nom_complet"] ?? "Utilisateur";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text("Tableau de bord",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshStats,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStats,
        color: _primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(fullname, role),
              const SizedBox(height: 24),
              if (_statsFuture == null)
                const Center(child: CircularProgressIndicator()),
              if (_statsFuture != null)
                FutureBuilder<Map<String, dynamic>>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(color: _primaryColor),
                      ));
                    }
                    if (snapshot.hasError) {
                      return _buildErrorCard(
                          onRefresh: _refreshStats,
                          error: snapshot.error.toString());
                    }
                    if (!snapshot.hasData) {
                      return _buildErrorCard(
                          onRefresh: _refreshStats,
                          error: "Aucune donnée reçue.");
                    }

                    final data = snapshot.data!;
                    return _buildStatsSection(data);
                  },
                ),
              const SizedBox(height: 24),
              _buildNavigationGrid(context, role),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS D'INTERFACE ---

  Widget _buildHeader(String fullname, String role) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_primaryColor, Color(0xFF357ABD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.person, size: 36, color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bonjour,",
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(fullname,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(role.toUpperCase(),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        letterSpacing: 1.2)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> data) {
    final arriereStats = Map<String, dynamic>.from(data['arriere_stats'] ?? {});
    final operationStats =
        Map<String, dynamic>.from(data['operation_stats'] ?? {});
    final events = List<Map<String, dynamic>>.from(data['events'] ?? []);
    final mesCotisations = data['mes_cotisations'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Aperçu financier",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Si c'est un membre simple, on affiche ses cotisations perso
        if (mesCotisations != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildStatCard("Mes Cotisations",
                _formatCurrency(mesCotisations), Icons.savings, _successColor),
          ),

        // Si Admin/Tresorier, on affiche les totaux globaux
        if (data.containsKey('tot_mensuelles'))
          Row(children: [
            Expanded(
                child: _buildStatCard(
                    "Cotisations Globales",
                    _formatCurrency(data['tot_mensuelles']),
                    Icons.groups,
                    _successColor)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    "Autres Recettes",
                    _formatCurrency(data['tot_autres']),
                    Icons.account_balance_wallet,
                    Colors.blue)),
          ]),

        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _buildStatCard("Dons", _formatCurrency(data['tot_dons']),
                  Icons.volunteer_activism, _purpleColor)),
          const SizedBox(width: 12),
          Expanded(
              child: _buildArrearsCard(
                  int.parse(data['arrieres'].toString()), arriereStats)),
        ]),

        const SizedBox(height: 16),
        _buildStatCard(
            "Total Opérations",
            "${operationStats['total_operations'] ?? 0} (${_formatCurrency(operationStats['montant_operations'])})",
            Icons.sync_alt,
            _warningColor),
        const SizedBox(height: 24),

        const Text("Prochains Événements",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildEventsList(events),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildArrearsCard(int membersCount, Map<String, dynamic> stats) {
    final montantDu = stats['montant_du'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: _dangerColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _dangerColor.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _dangerColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.warning_amber_outlined,
                  color: _dangerColor, size: 24)),
          const SizedBox(height: 16),
          Text("Arriérés ($membersCount pers.)",
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          if (montantDu > 0)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(_formatCurrency(montantDu),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _dangerColor)),
            )
          else
            const Text("0 FCFA",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _dangerColor))
        ],
      ),
    );
  }

  Widget _buildEventsList(List<dynamic> events) {
    if (events.isEmpty) {
      return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: const Text("Aucun événement à venir",
              style: TextStyle(color: Colors.grey)));
    }
    return Column(children: events.map((e) => _eventCard(e)).toList());
  }

  Widget _eventCard(dynamic event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.event, color: _primaryColor)),
        title: Text(event['titre'] ?? "Événement",
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_formatEventDate(event['date_evenement']),
            style: TextStyle(color: Colors.grey.shade600)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  String _formatEventDate(String? dateString) {
    if (dateString == null) return 'Date non définie';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMM yyyy', 'fr_FR').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildErrorCard(
      {required VoidCallback onRefresh, required String error}) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text("Erreur de chargement",
                style: TextStyle(
                    color: Colors.red.shade800, fontWeight: FontWeight.bold)),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text("Réessayer"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _dangerColor,
                    foregroundColor: Colors.white))
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationGrid(BuildContext context, String role) {
    List<Widget> items = [];

    // Menu pour Admin
    if (role == "admin") {
      items = [
        _buildNavigationTile(
            context, "Membres", Icons.group, const MembersListScreen()),
        _buildNavigationTile(
            context, "Catégories", Icons.category, const CategoryScreen()),
        _buildNavigationTile(context, "Opérations", Icons.account_balance,
            const OperationsScreen()),
        _buildNavigationTile(
            context, "Réunions", Icons.meeting_room, const ReunionsScreen()),
        _buildNavigationTile(
            context,
            "Présences",
            Icons.check_circle,
            const ReunionPresenceScreen(
                reunionId: 0)), // Id 0 temporaire pour la liste
        _buildNavigationTile(context, "Créer réunion", Icons.add_business,
            const ReunionAddScreen()),
        // Important: On passe un membre vide ou l'actuel pour l'écran Events
        _buildNavigationTile(context, "Événements", Icons.event,
            const EventsScreen(membre: {"role": "admin"})),
        _buildNavigationTile(context, "Créer événement", Icons.add_alert,
            const EventAddScreen()),
        _buildNavigationTile(context, "Calendrier", Icons.calendar_month,
            const EventCalendarScreen()),
        _buildNavigationTile(
            context, "Profil", Icons.person, const ProfileScreen()),
      ];
    }
    // Menu pour Secrétaire
    else if (role == "secretaire") {
      items = [
        _buildNavigationTile(
            context, "Réunions", Icons.meeting_room, const ReunionsScreen()),
        _buildNavigationTile(
            context,
            "Présences",
            Icons.check_circle,
            const ReunionPresenceScreen(
                reunionId: 0)), // Id 0 temporaire pour la liste
        _buildNavigationTile(context, "Créer réunion", Icons.add_business,
            const ReunionAddScreen()),
        _buildNavigationTile(
            context,
            "Événements",
            Icons.event,
            const EventsScreen(membre: {
              "role": "admin"
            })), // Admin role passed to allow editing
        _buildNavigationTile(context, "Créer événement", Icons.add_alert,
            const EventAddScreen()),
        _buildNavigationTile(context, "Calendrier", Icons.calendar_month,
            const EventCalendarScreen()),
        _buildNavigationTile(
            context, "Profil", Icons.person, const ProfileScreen()),
      ];
    }
    // Menu pour Membre simple
    else {
      items = [
        _buildNavigationTile(
            context, "Mon Profil", Icons.person, const ProfileScreen()),
        _buildNavigationTile(
            context,
            "Mes Cotisations",
            Icons.account_balance_wallet,
            const OperationsScreen()), // À adapter pour vue membre
        _buildNavigationTile(context, "Événements", Icons.event,
            EventsScreen(membre: {"role": role})),
        _buildNavigationTile(context, "Calendrier", Icons.calendar_month,
            const EventCalendarScreen()),
      ];
    }

    return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.15,
        children: items);
  }

  Widget _buildNavigationTile(
      BuildContext context, String title, IconData icon, Widget page) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      borderRadius: BorderRadius.circular(16),
      splashColor: _primaryColor.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 38, color: _primaryColor),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800))
        ]),
      ),
    );
  }
}
