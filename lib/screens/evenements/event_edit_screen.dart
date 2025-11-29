import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/event_service.dart';

class EventEditScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventEditScreen({super.key, required this.event});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titreController;
  late TextEditingController _descController;
  late TextEditingController _lieuController;
  late TextEditingController _dateController;

  String? _selectedType;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. On pré-remplit les champs avec les données actuelles de l'événement
    _titreController = TextEditingController(text: widget.event['titre']);
    _descController = TextEditingController(text: widget.event['description']);
    _lieuController = TextEditingController(text: widget.event['lieu']);
    _selectedType = widget.event['type'];

    // Gestion de la date
    if (widget.event['date_evenement'] != null) {
      try {
        _selectedDate = DateTime.parse(widget.event['date_evenement']);
        _dateController = TextEditingController(
            text: DateFormat('yyyy-MM-dd').format(_selectedDate!));
      } catch (e) {
        _dateController = TextEditingController();
      }
    } else {
      _dateController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descController.dispose();
    _lieuController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale("fr", "FR"),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Titre et Date sont obligatoires")));
      return;
    }

    setState(() => _isLoading = true);

    // 2. On prépare les données mises à jour
    Map<String, dynamic> data = {
      "id": widget.event['id'], // ID essentiel pour l'update
      "titre": _titreController.text,
      "description": _descController.text,
      "lieu": _lieuController.text,
      "type": _selectedType ?? "Autre",
      "date_evenement": _dateController.text,
      "statut": widget.event['statut'], // On garde le statut actuel
      "couleur": widget.event['couleur'] // On garde la couleur actuelle
    };

    // 3. Appel au service
    final res = await EventService.update(data);

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Modifications enregistrées !")));
        Navigator.pop(context, true); // Renvoie TRUE pour dire "ça a changé"
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erreur: ${res['message']}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier l'événement")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                    labelText: "Titre *", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                    labelText: "Type", border: OutlineInputBorder()),
                items: ["Réunion", "Activité", "Sortie", "AG", "Autre"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: "Date *",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lieuController,
                decoration: const InputDecoration(
                    labelText: "Lieu", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                    labelText: "Description", border: OutlineInputBorder()),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ENREGISTRER"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
