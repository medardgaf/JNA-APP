import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Assure-toi d'avoir intl dans pubspec.yaml
import '../../services/event_service.dart';
import 'event_add_screen.dart';

class EventsScreen extends StatefulWidget {
  final Map<String, dynamic> membre;

  const EventsScreen({super.key, required this.membre});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  // --- ETAT ---
  List<dynamic> events = [];
  bool loading = true;
  String? filterType;
  String searchQuery = "";

  // Contrôleurs dates
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  String? _dateFrom;
  String? _dateTo;

  @override
  void initState() {
    super.initState();
    _debugAdminStatus(); // Vérification console au démarrage
    _loadEvents();
  }

  @override
  void dispose() {
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  // --- LOGIQUE ADMIN ---
  bool _checkIfAdmin() {
    // Récupération sécurisée et nettoyage de la chaîne
    final role = (widget.membre["role"] ?? "").toString().trim().toLowerCase();
    // Accepte "admin", "administrateur", ou "superadmin"
    return role == "admin" || role == "administrateur" || role == "superadmin";
  }

  void _debugAdminStatus() {
    print("--- DEBUG ADMIN ---");
    print("Données membre reçues : ${widget.membre}");
    print("Rôle brut : '${widget.membre["role"]}'");
    print("Est considéré Admin ? : ${_checkIfAdmin()}");
    print("-------------------");
  }

  // --- CHARGEMENT DES DONNÉES ---
  Future<void> _loadEvents() async {
    setState(() => loading = true);
    try {
      final res = await EventService.getAll(
        type: filterType,
        q: searchQuery.isEmpty ? null : searchQuery,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );
      if (mounted) {
        setState(() {
          events = res["data"] ?? [];
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _showSnackBar("Erreur de chargement: $e", isError: true);
      }
    }
  }

  // --- ACTIONS ---
  Future<void> _markAsDone(dynamic e) async {
    try {
      final int id = int.tryParse(e["id"].toString()) ?? 0;
      final res = await EventService.markAsDone(id);
      if (res["success"] == true) {
        _showSnackBar("Événement marqué comme fait ✅");
        _loadEvents();
      } else {
        _showSnackBar(res["message"] ?? "Erreur inconnue", isError: true);
      }
    } catch (e) {
      _showSnackBar("Erreur: $e", isError: true);
    }
  }

  Future<void> _deleteEvent(dynamic e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text("Voulez-vous vraiment supprimer \"${e["titre"]}\" ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final int id = int.tryParse(e["id"].toString()) ?? 0;
        final res = await EventService.delete(id);
        if (res["success"] == true) {
          _showSnackBar("Événement supprimé");
          _loadEvents();
        } else {
          _showSnackBar(res["message"] ?? "Erreur inconnue", isError: true);
        }
      } catch (e) {
        _showSnackBar("Erreur: $e", isError: true);
      }
    }
  }

  // --- NOUVELLE FONCTION POUR MODIFIER ---
  Future<void> _editEvent(dynamic e) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventAddScreen(
          event: e, // On passe l'événement à modifier
          isEditMode: true, // On indique qu'on est en mode édition
        ),
      ),
    );
    if (result == true) _loadEvents();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // --- INTERFACE ---
  @override
  Widget build(BuildContext context) {
    final isAdmin = _checkIfAdmin();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Événements"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: "Rafraîchir",
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadEvents,
                    child: events.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: events.length,
                            padding: const EdgeInsets.only(bottom: 80),
                            itemBuilder: (_, i) =>
                                _eventCard(events[i], isAdmin),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventAddScreen()),
                );
                if (result == true) _loadEvents();
              },
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Aucun événement trouvé",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Rechercher...",
                    prefixIcon: Icon(Icons.search),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  onChanged: (value) {
                    searchQuery = value;
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) _loadEvents();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                hint: const Text("Type"),
                value: filterType,
                items: ["Réunion", "Activité", "Sortie", "AG", "Autre"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() => filterType = value);
                  _loadEvents();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child:
                    _buildDatePickerField("Début", _dateFromController, true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDatePickerField("Fin", _dateToController, false),
              ),
              IconButton(
                icon: const Icon(Icons.filter_alt_off),
                onPressed: () {
                  setState(() {
                    _dateFrom = null;
                    _dateTo = null;
                    _dateFromController.clear();
                    _dateToController.clear();
                    filterType = null;
                    searchQuery = "";
                  });
                  _loadEvents();
                },
                tooltip: "Effacer tout",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField(
      String label, TextEditingController controller, bool isFrom) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      readOnly: true,
      onTap: () => _selectDate(context, isFrom),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      final displayDate = DateFormat('dd/MM/yyyy').format(pickedDate);

      setState(() {
        if (isFromDate) {
          _dateFrom = formattedDate;
          _dateFromController.text = displayDate;
        } else {
          _dateTo = formattedDate;
          _dateToController.text = displayDate;
        }
      });
      _loadEvents();
    }
  }

  Widget _eventCard(dynamic e, bool isAdmin) {
    final color = _hexToColor(e["couleur"] ?? "#2196F3");
    final isDone = (e["statut"] ?? "") == "fait";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EventDetailScreen(event: e, membre: widget.membre),
            ),
          );
          if (result == true) _loadEvents();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Indicateur de couleur vertical
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: isDone ? Colors.grey : color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Contenu texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e["titre"] ?? "Sans titre",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDone ? Colors.grey : Colors.black87,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(e["date_evenement"] ?? ""),
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        if (e["type"] != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              e["type"],
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 11),
                            ),
                          ),
                        ]
                      ],
                    ),
                    if (e["lieu"] != null && e["lieu"].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.place,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                e["lieu"],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Actions Admin rapides
              if (isAdmin)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editEvent(e); // NOUVEAU
                    if (value == 'done') _markAsDone(e);
                    if (value == 'delete') _deleteEvent(e);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit', // NOUVEAU
                      child: Row(children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text("Modifier")
                      ]),
                    ),
                    if (!isDone)
                      const PopupMenuItem(
                        value: 'done',
                        child: Row(children: [
                          Icon(Icons.check, color: Colors.green),
                          SizedBox(width: 8),
                          Text("Fait")
                        ]),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text("Supprimer")
                      ]),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UTILITAIRES ---
  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex";
    return Color(int.parse(hex, radix: 16));
  }
}

// ############################################################################
// ########################## ÉCRAN DE DÉTAIL #################################
// ############################################################################

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final Map<String, dynamic> membre;

  const EventDetailScreen(
      {super.key, required this.event, required this.membre});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Map<String, dynamic> event;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    event = Map.from(widget.event);
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex";
    return Color(int.parse(hex, radix: 16));
  }

  bool _isAdmin() {
    final role = (widget.membre["role"] ?? "").toString().trim().toLowerCase();
    return role == "admin" || role == "administrateur" || role == "superadmin";
  }

  // NOUVELLE FONCTION POUR MODIFIER
  Future<void> _editEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventAddScreen(
          event: event, // On passe l'événement à modifier
          isEditMode: true, // On indique qu'on est en mode édition
        ),
      ),
    );
    if (result == true) {
      Navigator.pop(context, true); // On retourne true pour rafraîchir la liste
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(event["couleur"] ?? "#2196F3");
    final isDone = (event["statut"] ?? "") == "fait";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détail"),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          // NOUVEAU BOUTON MODIFIER
          if (_isAdmin())
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editEvent,
              tooltip: "Modifier",
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(event["type"] ?? "Autre"),
                        backgroundColor: Colors.white,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDone ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isDone ? "TERMINÉ" : "PLANIFIÉ",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event["titre"] ?? "Sans titre",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Infos
            _buildInfoRow(Icons.calendar_today, "Date",
                _formatFullDate(event["date_evenement"] ?? "")),
            if (event["lieu"] != null)
              _buildInfoRow(Icons.location_on, "Lieu", event["lieu"]),

            const SizedBox(height: 24),
            const Text("Description",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                event["description"] ?? "Aucune description",
                style: const TextStyle(
                    fontSize: 16, height: 1.5, color: Colors.black87),
              ),
            ),

            // Boutons Admin
            if (_isAdmin()) ...[
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (!isDone)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text("Marquer Fait"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          // Logique identique à l'écran précédent
                          // (A adapter selon préférence : appel API direct ici)
                          setState(() => event["statut"] = "fait");
                          final int id =
                              int.tryParse(event["id"].toString()) ?? 0;
                          await EventService.markAsDone(id);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Mis à jour !")));
                        },
                      ),
                    ),
                  if (!isDone) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text("Supprimer"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        // Logique suppression
                        final int id =
                            int.tryParse(event["id"].toString()) ?? 0;
                        await EventService.delete(id);
                        Navigator.pop(context, true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(String dateStr) {
    try {
      return DateFormat('EEEE d MMMM yyyy', 'fr_FR')
          .format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }
}
