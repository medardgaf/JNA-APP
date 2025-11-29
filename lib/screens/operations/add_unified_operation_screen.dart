import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/membre_service.dart';
import '../../services/CategoryService.dart';
import '../../services/operations_services.dart';
import 'package:url_launcher/url_launcher.dart';

class AddUnifiedOperationScreen extends StatefulWidget {
  final Map<String, dynamic>? operation;
  final String? preselectedType;
  final int? preselectedCategorieId;
  final bool forceCategorie;

  const AddUnifiedOperationScreen({
    super.key,
    this.operation,
    this.preselectedType,
    this.preselectedCategorieId,
    this.forceCategorie = false,
  });

  @override
  State<AddUnifiedOperationScreen> createState() =>
      _AddUnifiedOperationScreenState();
}

class _AddUnifiedOperationScreenState extends State<AddUnifiedOperationScreen> {
  String? _selectedType;
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedMember;
  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _filteredCategories = [];

  bool _isLoading = true;
  bool _isSubmitting = false;

  final _montantController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final categoriesFuture = CategoryService.getAll();
      final membersFuture = MembreService.getAll();
      final results = await Future.wait([categoriesFuture, membersFuture]);
      if (mounted) {
        setState(() {
          _allCategories = List<Map<String, dynamic>>.from(results[0]);
          _allMembers = List<Map<String, dynamic>>.from(results[1]);
          _isLoading = false;
        });

        if (widget.operation != null) {
          _populateFieldsForEdit();
        } else {
          // Utiliser les valeurs présélectionnées si fournies
          _selectedType = widget.preselectedType ?? 'recette';
          _filterCategoriesByType();

          // Présélectionner la catégorie si fournie
          if (widget.preselectedCategorieId != null) {
            _selectedCategory = _allCategories.firstWhere(
              (cat) => cat['id'] == widget.preselectedCategorieId,
              orElse: () => {},
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erreur de chargement: $e")));
      }
    }
  }

  void _populateFieldsForEdit() {
    final op = widget.operation!;
    setState(() {
      _selectedType = op['type']?.toString();

      final originalCategoryId = op['categorie_id'];
      _selectedCategory = _findCategoryById(originalCategoryId) ??
          {
            'id': originalCategoryId,
            'nom': op['categorie_nom']?.toString() ?? 'Catégorie inconnue',
            'type': op['categorie_type']?.toString() ??
                op['type']?.toString() ??
                'recette'
          };

      if (op['membre_id'] != null) {
        final originalMemberId = op['membre_id'];
        _selectedMember = _findMemberById(originalMemberId) ??
            {
              'id': originalMemberId,
              'nom': op['membre_nom']?.toString() ?? '',
              'prenom': op['membre_prenom']?.toString() ?? ''
            };
      } else {
        _selectedMember = null;
      }

      _montantController.text = op['montant']?.toString() ?? '';
      _dateController.text = op['date_operation']?.toString() ?? '';
      _descriptionController.text = op['description']?.toString() ?? '';
    });

    _filterCategoriesByType();
  }

  Map<String, dynamic>? _findCategoryById(dynamic categoryId) {
    if (categoryId == null) return null;

    final categoryIdStr = categoryId.toString();
    try {
      return _allCategories.firstWhere(
        (cat) {
          final catId = cat['id'];
          if (catId == null) return false;
          return catId.toString() == categoryIdStr;
        },
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? _findMemberById(dynamic memberId) {
    if (memberId == null) return null;

    final memberIdStr = memberId.toString();
    try {
      return _allMembers.firstWhere(
        (member) {
          final mId = member['id'];
          if (mId == null) return false;
          return mId.toString() == memberIdStr;
        },
      );
    } catch (e) {
      return null;
    }
  }

  void _onTypeSelected(String type) {
    setState(() {
      _selectedType = type;
      _selectedCategory = null;
    });
    _filterCategoriesByType();
  }

  void _filterCategoriesByType() {
    if (_allCategories.isEmpty) return;

    setState(() {
      _filteredCategories =
          _allCategories.where((cat) => cat['type'] == _selectedType).toList();

      if (widget.operation != null && _selectedCategory != null) {
        final selectedCatInFiltered = _filteredCategories
            .any((cat) => _compareIds(cat['id'], _selectedCategory!['id']));

        if (!selectedCatInFiltered && _filteredCategories.isNotEmpty) {
          _selectedCategory = _filteredCategories.first;
        }
      } else if (_filteredCategories.isNotEmpty && _selectedCategory == null) {
        _selectedCategory = _filteredCategories.first;
      }
    });
  }

  bool _compareIds(dynamic id1, dynamic id2) {
    if (id1 == null || id2 == null) return false;
    return id1.toString() == id2.toString();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez sélectionner une catégorie")));
      return;
    }

    if (_isCotisationMensuelle && _selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Veuillez sélectionner un membre pour la cotisation mensuelle")));
      return;
    }

    final montantText = _montantController.text.trim().replaceAll(' ', '');
    final montant = double.tryParse(montantText);
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez entrer un montant valide")));
      return;
    }

    if (_dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez sélectionner une date")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final categoryId = _parseId(_selectedCategory!['id']);
      if (categoryId == null) {
        throw Exception("ID de catégorie invalide");
      }

      final memberId =
          _selectedMember != null ? _parseId(_selectedMember!['id']) : null;

      debugPrint(
          "Envoi des données - Type: $_selectedType, Catégorie ID: $categoryId, Membre ID: $memberId, Montant: $montant");

      final operationId =
          widget.operation != null ? _parseId(widget.operation!['id']) : null;

      if (widget.operation != null && operationId == null) {
        throw Exception("ID d'opération invalide pour la modification");
      }

      final res = widget.operation != null
          ? await OperationService.update(
              id:
                  operationId!, // ✅ Utilisation de l'opérateur ! car on a vérifié que c'est non null
              type: _selectedType!,
              categorieId: categoryId,
              membreId: memberId,
              montant: montant,
              dateOperation: _dateController.text.trim(),
              description: _descriptionController.text.trim())
          : await OperationService.add(
              type: _selectedType!,
              categorieId: categoryId,
              membreId: memberId,
              montant: montant,
              dateOperation: _dateController.text.trim(),
              description: _descriptionController.text.trim());

      setState(() => _isSubmitting = false);

      if (mounted) {
        if (res["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res["message"] ?? "Action effectuée")));

          // Logique WhatsApp
          bool shouldPop = true;
          if (_selectedMember != null) {
            final phone = _selectedMember!['telephone']?.toString();
            if (phone != null && phone.isNotEmpty) {
              shouldPop = false; // On attend la réponse du dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Notification WhatsApp"),
                  content: Text(
                      "Voulez-vous envoyer un reçu WhatsApp à ${_selectedMember!['nom']} ${_selectedMember!['prenom']} ?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Non"),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text("Oui, envoyer"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                final nom = _selectedMember!['nom'] ?? "";
                final prenom = _selectedMember!['prenom'] ?? "";
                final typeStr =
                    _selectedType == 'recette' ? 'Recette' : 'Dépense';
                final montantStr = _montantController.text;
                final descStr = _descriptionController.text.isNotEmpty
                    ? " (${_descriptionController.text})"
                    : "";

                final message =
                    "Bonjour $nom $prenom, votre opération de $montantStr FCFA ($typeStr) a été enregistrée avec succès$descStr. Merci !";

                // Nettoyage du numéro (enlève les espaces, tirets, etc.)
                final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

                final url = Uri.parse(
                    "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");

                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Impossible d'ouvrir WhatsApp")),
                  );
                }
              }
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            }
          }

          if (shouldPop && mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res["message"] ?? "Erreur inconnue")));
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
    }
  }

  int? _parseId(dynamic id) {
    if (id == null) return null;

    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    if (id is double) return id.toInt();

    final idString = id.toString();
    return int.tryParse(idString);
  }

  bool get _isCotisationMensuelle {
    if (_selectedCategory == null) return false;
    final categoryName =
        _selectedCategory!['nom']?.toString().toLowerCase() ?? '';
    return categoryName.contains('cotisation');
  }

  bool get _shouldShowMemberSelector {
    if (_selectedCategory == null) return false;
    return _selectedType == 'recette';
  }

  bool get _isMemberRequired {
    return _isCotisationMensuelle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.operation != null
            ? "Modifier l'Opération"
            : "Nouvelle Opération"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 24),
                    _buildCategorySelector(),
                    const SizedBox(height: 16),
                    if (_shouldShowMemberSelector) ...[
                      _buildMemberSelector(),
                      const SizedBox(height: 16),
                    ],
                    _buildOperationDetailsForm(),
                    if (_isCotisationMensuelle) _buildCotisationInfoCard(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Type d'opération",
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(
          children: ['recette', 'depense'].map((type) {
            final isSelected = _selectedType == type;
            final label = type == 'recette' ? 'Recette' : 'Dépense';
            return Expanded(
              child: GestureDetector(
                onTap: () => _onTypeSelected(type),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (type == 'recette' ? Colors.green : Colors.red)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedCategory,
      decoration: const InputDecoration(
          labelText: "Catégorie",
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.category)),
      items: _filteredCategories.map((category) {
        return DropdownMenuItem(
            value: category,
            child: Text(category['nom']?.toString() ?? 'Sans nom'));
      }).toList(),
      onChanged: (category) {
        setState(() {
          _selectedCategory = category;
        });
      },
    );
  }

  Widget _buildMemberSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _selectedMember,
          decoration: InputDecoration(
            labelText: _isMemberRequired
                ? "Membre concerné *"
                : "Membre concerné (optionnel)",
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.person_search),
          ),
          items: [
            if (!_isMemberRequired)
              const DropdownMenuItem(
                value: null,
                child: Text(
                  "Aucun membre (opération générale)",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ..._allMembers.map((member) {
              final nom = member['nom']?.toString() ?? '';
              final prenom = member['prenom']?.toString() ?? '';
              return DropdownMenuItem(
                  value: member, child: Text("$nom $prenom"));
            }),
          ],
          onChanged: (member) => setState(() => _selectedMember = member),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            _isMemberRequired
                ? "Requis pour les cotisations mensuelles"
                : "Optionnel - pour associer cette opération à un membre spécifique",
            style: TextStyle(
              fontSize: 12,
              color: _isMemberRequired
                  ? Colors.blue.shade700
                  : Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationDetailsForm() {
    return Column(
      children: [
        TextFormField(
          controller: _montantController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: "Montant (FCFA)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money)),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: const InputDecoration(
                labelText: "Date de l'opération",
                hintText: "AAAA-MM-JJ",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today)),
            child: Text(
                _dateController.text.isEmpty
                    ? "Sélectionner une date"
                    : _dateController.text,
                style: TextStyle(
                    color: _dateController.text.isEmpty
                        ? Colors.grey
                        : Colors.black)),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: "Description (optionnelle)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description)),
        ),
      ],
    );
  }

  Widget _buildCotisationInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Information sur la cotisation :",
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
              "Le système paiera les mois passés, présents et futurs tant que le montant est suffisant."),
          Text("Tarif : 250 FCFA/mois (à partir de 2024)."),
          Text(
              "Le reste (si inférieur à un mois) sera ajouté au crédit du membre."),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            backgroundColor:
                _selectedType == 'recette' ? Colors.green : Colors.red),
        icon: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3))
            : const Icon(Icons.payment),
        label: Text(
            _isSubmitting ? "Enregistrement..." : "Enregistrer l'opération",
            style: const TextStyle(fontSize: 16, color: Colors.white)),
        onPressed: _isSubmitting ? null : _submit,
      ),
    );
  }
}
