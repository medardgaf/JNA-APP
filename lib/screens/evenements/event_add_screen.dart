import 'package:flutter/material.dart';
import '../../services/event_service.dart'; // Assurez-vous que le chemin est correct

class EventAddScreen extends StatefulWidget {
  // Paramètres pour gérer l'ajout ET la modification
  final Map<String, dynamic>?
      event; // null si ajout, contient les données si modification
  final bool isEditMode; // true si on modifie, false si on ajoute

  const EventAddScreen({
    super.key,
    this.event,
    this.isEditMode = false,
  });

  @override
  State<EventAddScreen> createState() => _EventAddScreenState();
}

class _EventAddScreenState extends State<EventAddScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Contrôleurs pour les champs du formulaire
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lieuController = TextEditingController();
  final _dateController = TextEditingController();

  // Variables pour les sélections
  String? _selectedType;
  Color _selectedColor = Colors.blue;

  // Listes pour les Dropdowns et sélecteurs
  final List<String> _types = ["Réunion", "Activité", "Sortie", "AG", "Autre"];
  final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    // Si on est en mode édition, on pré-remplit les champs avec les données de l'événement
    if (widget.isEditMode && widget.event != null) {
      _titreController.text = widget.event!["titre"] ?? "";
      _descriptionController.text = widget.event!["description"] ?? "";
      _lieuController.text = widget.event!["lieu"] ?? "";
      _dateController.text = widget.event!["date_evenement"] ?? "";
      _selectedType = widget.event!["type"];
      _selectedColor = _hexToColor(widget.event!["couleur"] ?? "#2196F3");
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _lieuController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isEditMode ? "Modifier l'événement" : "Nouvel événement"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Champ Titre
                    TextFormField(
                      controller: _titreController,
                      decoration: const InputDecoration(
                        labelText: "Titre de l'événement *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Veuillez entrer un titre";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Champ Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Champ Date
                    TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: "Date de l'événement *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: _selectDate,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Veuillez sélectionner une date";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Champ Lieu
                    TextFormField(
                      controller: _lieuController,
                      decoration: const InputDecoration(
                        labelText: "Lieu",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Champ Type
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Type d'événement",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                      value: _selectedType,
                      items: _types.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sélecteur de couleur
                    const Text(
                      "Couleur de l'événement",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colors.map((color) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColor == color
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: _selectedColor == color
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Bouton de création/modification
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _submitForm,
                      icon: isLoading
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(isLoading
                          ? (widget.isEditMode
                              ? "Modification..."
                              : "Création...")
                          : (widget.isEditMode
                              ? "Modifier l'événement"
                              : "Créer l'événement")),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Ouvre le sélecteur de date
  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateController.text.isNotEmpty
          ? DateTime.parse(_dateController.text)
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Soumet le formulaire pour créer ou modifier l'événement
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => isLoading = true);

    try {
      Map<String, dynamic> res;

      if (widget.isEditMode) {
        // --- MODE MODIFICATION ---
        // On prépare la Map de données pour votre service
        final eventData = {
          "id":
              widget.event!["id"], // L'ID est indispensable pour la mise à jour
          "titre": _titreController.text.trim(),
          "date_evenement": _dateController.text,
          "description": _descriptionController.text.trim(),
          "lieu": _lieuController.text.trim(),
          "type": _selectedType,
          "couleur": _colorToHex(_selectedColor),
        };
        res = await EventService.update(eventData);
      } else {
        // --- MODE AJOUT ---
        res = await EventService.add(
          titre: _titreController.text.trim(),
          dateEvenement: _dateController.text,
          description: _descriptionController.text.trim(),
          lieu: _lieuController.text.trim(),
          type: _selectedType,
          couleur: _colorToHex(_selectedColor),
        );
      }

      if (res["success"] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEditMode
                  ? "Événement modifié avec succès !"
                  : "Événement créé avec succès !"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(
              context, true); // Retourne 'true' pour indiquer un succès
        }
      } else {
        throw Exception(res["message"] ?? "Une erreur est survenue");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // Convertit un objet Color en chaîne hexadécimale
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // Convertit un code hexadécimal en objet Color
  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex";
    return Color(int.parse(hex, radix: 16));
  }
}
